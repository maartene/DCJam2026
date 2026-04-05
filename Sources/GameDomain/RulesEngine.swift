// RulesEngine — pure function driving port: (GameState, GameCommand, deltaTime) → GameState.
// All game rules live here. No I/O, no side effects.

public enum RulesEngine {

    public static func apply(command: GameCommand, to state: GameState, deltaTime: Double) -> GameState {
        // Start screen: timers are paused; any non-idle command transitions to dungeon then continues.
        let resolvedState: GameState
        if case .startScreen = state.screenMode {
            guard command != .none else { return state }
            // Transition to dungeon, then process the command normally (no timer advance on start screen).
            resolvedState = state.withScreenMode(.dungeon)
        } else {
            resolvedState = state
        }

        // Advance timers first on every tick.
        let next = advanceTimers(resolvedState, deltaTime: deltaTime)

        // On the upgrade prompt screen, keys 1/2/3 select an upgrade rather than triggering
        // dash/brace/special. Remap before the main dispatch.
        let resolvedCommand: GameCommand
        if case .upgradePrompt(let choices) = next.screenMode {
            switch command {
            case .dash   where choices.count > 0: resolvedCommand = .selectUpgrade(choices[0])
            case .brace  where choices.count > 1: resolvedCommand = .selectUpgrade(choices[1])
            case .special where choices.count > 2: resolvedCommand = .selectUpgrade(choices[2])
            default: resolvedCommand = command
            }
        } else {
            resolvedCommand = command
        }

        switch resolvedCommand {
        case .none:
            return next

        case .move(let direction):
            return applyMove(direction, to: next)

        case .turn(let dir):
            return applyTurn(dir, to: next)

        case .dash:
            return applyDash(to: next)

        case .brace:
            return applyBrace(to: next)

        case .special:
            return applySpecial(to: next)

        case .confirmOverlay:
            return applyConfirmOverlay(to: next)

        case .selectUpgrade(let upgrade):
            return applyUpgrade(upgrade, to: next)

        case .restart:
            return GameState.initial(config: state.config)
        }
    }

    // MARK: - Timer advancement

    private static func advanceTimers(_ state: GameState, deltaTime: Double) -> GameState {
        guard deltaTime > 0 else { return state }

        let (replenished, newTimerModel) = state.timerModel.advance(
            deltaTime: deltaTime,
            cooldownDuration: state.config.dashCooldownSeconds
        )
        let newCharges = min(state.dashCharges + replenished, state.config.dashChargeCap)
        let newSpecial = min(state.specialCharge + state.config.specialChargeRatePerSecond * deltaTime, 1.0)

        let newBraceWindow = max(state.braceWindowTimer - deltaTime, 0.0)
        let newBraceCooldown = max(state.braceCooldownTimer - deltaTime, 0.0)
        // Capture brace-active status BEFORE decrement: if window was open at tick start,
        // it covers any attack that fires during this tick (discrete-tick game rule).
        let braceWasActive = state.braceWindowTimer > 0

        // Decrement transient overlay frame counter; clear when it reaches zero.
        let newOverlay: TransientOverlay?
        switch state.transientOverlay {
        case .braceSuccess(let f) where f > 1:
            newOverlay = .braceSuccess(framesRemaining: f - 1)
        case .braceHit(let f) where f > 1:
            newOverlay = .braceHit(framesRemaining: f - 1)
        case .dash(let f) where f > 1:
            newOverlay = .dash(framesRemaining: f - 1)
        case .special(let f) where f > 1:
            newOverlay = .special(framesRemaining: f - 1)
        default:
            // framesRemaining == 1 (expires this tick) or nil
            newOverlay = nil
        }

        var next = state
            .withTimerModel(newTimerModel)
            .withDashCharges(newCharges)
            .withSpecialCharge(newSpecial)
            .withBraceWindowTimer(newBraceWindow)
            .withBraceCooldownTimer(newBraceCooldown)
            .withTransientOverlay(newOverlay)

        // Enemy attack timer fires only in combat.
        if case .combat(var encounter) = next.screenMode {
            encounter.enemyAttackTimer -= deltaTime
            next = applyEnemyAttackTick(to: next, encounter: encounter, braceWasActive: braceWasActive)
        }

        return next
    }

    private static func applyEnemyAttackTick(
        to state: GameState,
        encounter: EncounterModel,
        braceWasActive: Bool
    ) -> GameState {
        guard encounter.enemyAttackTimer <= 0 else {
            return state.withScreenMode(.combat(encounter: encounter))
        }
        var resetEncounter = encounter
        resetEncounter.enemyAttackTimer = state.config.enemyAttackInterval

        if braceWasActive {
            // Parry — absorb hit, zero HP damage, grant Special charge bonus.
            let bonusSpecial = min(state.specialCharge + state.config.braceSpecialBonus, 1.0)
            return state
                .withSpecialCharge(bonusSpecial)
                .withScreenMode(.combat(encounter: resetEncounter))
                .withTransientOverlay(.braceSuccess(framesRemaining: TransientOverlay.defaultDuration))
        }

        // Full unbraced hit.
        let newHP = max(state.hp - encounter.baseDamage, 0)
        if newHP == 0 {
            // Fatal hit — death state, no overlay.
            return state
                .withHP(0)
                .withScreenMode(.deathState)
                .withTransientOverlay(nil)
        }
        // Non-fatal unbraced hit.
        return state
            .withHP(newHP)
            .withScreenMode(.combat(encounter: resetEncounter))
            .withTransientOverlay(.braceHit(framesRemaining: TransientOverlay.defaultDuration))
    }

    // MARK: - Turning

    private static func applyTurn(_ turn: TurnDirection, to state: GameState) -> GameState {
        if case .combat = state.screenMode { return state }
        return state.withFacingDirection(state.facingDirection.turned(by: turn))
    }

    // MARK: - Movement

    private static func delta(facing: CardinalDirection, direction: MoveDirection) -> (dx: Int, dy: Int) {
        let forward = facing.forwardDelta
        return direction == .forward ? forward : (dx: -forward.dx, dy: -forward.dy)
    }

    private static func applyMove(_ direction: MoveDirection, to state: GameState) -> GameState {
        // Movement is locked when in combat — only Dash exits an encounter.
        if case .combat = state.screenMode { return state }
        // Movement is locked during narrative overlays — player must confirm first.
        if case .narrativeOverlay = state.screenMode { return state }

        // Clear the post-dash feedback on the first step after a dash.
        let state = state.withRecentDash(false)
        let floor = FloorRegistry.floor(state.currentFloor, config: state.config)

        let moveDelta = delta(facing: state.facingDirection, direction: direction)
        let newPos = Position(x: state.playerPosition.x + moveDelta.dx, y: state.playerPosition.y + moveDelta.dy)

        // Descend staircase — triggers when stepping onto or through the staircase cell.
        // Checked before the passability guard: the "step through" case lands out-of-bounds.
        let isAtOrPastStaircase = (newPos == floor.staircasePosition2D)
            || (state.playerPosition == floor.staircasePosition2D && direction == .forward)
        if !floor.hasExitSquare && isAtOrPastStaircase {
            let nextFloor = state.currentFloor + 1
            let nextFloorMap = FloorRegistry.floor(nextFloor, config: state.config)
            let advanced = state
                .withCurrentFloor(nextFloor)
                .withPlayerPosition(nextFloorMap.entryPosition)
                .withClearedEncounterPositions([])
            // Non-final descent: show upgrade prompt with 3 distinct choices not already taken.
            if nextFloor <= state.config.maxFloors {
                let pool = UpgradePool(alreadySelected: state.activeUpgrades)
                let choices = pool.drawChoices(count: state.config.upgradeChoiceCount)
                return advanced.withScreenMode(.upgradePrompt(choices: choices))
            }
            // Defensive guard: beyond final floor — return to dungeon directly.
            return advanced.withScreenMode(.dungeon)
        }

        // Wall collision — block movement into non-passable cells (walls or out-of-bounds).
        guard floor.grid.cell(x: newPos.x, y: newPos.y).isPassable else {
            return state
        }

        // Step onto exit square (requires egg for win).
        if floor.hasExitSquare && newPos == floor.exitPosition2D {
            if state.hasEgg {
                return state
                    .withPlayerPosition(newPos)
                    .withScreenMode(.narrativeOverlay(event: .exitPatio))
            }
            return state.withPlayerPosition(newPos)
        }

        // Step into egg room.
        if floor.hasEggRoom, let eggPos = floor.eggRoomPosition2D, newPos == eggPos, !state.hasEgg {
            return state
                .withPlayerPosition(newPos)
                .withScreenMode(.narrativeOverlay(event: .eggDiscovery))
        }

        // Step into an encounter.
        if let encounterPos = floor.encounterPosition2D, newPos == encounterPos {
            guard state.clearedEncounterPositions.contains(encounterPos) else {
                let encounter = EncounterModel.guard(isBossEncounter: floor.hasBossEncounter)
                return state.withPlayerPosition(newPos).withScreenMode(.combat(encounter: encounter))
            }
        }

        return state.withPlayerPosition(newPos)
    }

    // MARK: - Dash

    private static func applyDash(to state: GameState) -> GameState {
        guard case .combat(let encounter) = state.screenMode else { return state }
        guard !encounter.isBossEncounter else { return state }
        guard state.dashCharges > 0 else { return state }

        let newCharges = state.dashCharges - 1
        let newTimer = state.timerModel.addingCooldown(duration: state.config.dashCooldownSeconds)
        return state
            .withDashCharges(newCharges)
            .withTimerModel(newTimer)
            .withPlayerPosition(state.playerPosition + dashAdvanceSquares)
            .withScreenMode(.dungeon)
            .withRecentDash(true)
            .withTransientOverlay(.dash(framesRemaining: TransientOverlay.defaultDuration))
    }

    // MARK: - Brace

    private static func applyBrace(to state: GameState) -> GameState {
        guard case .combat = state.screenMode else { return state }
        guard !state.braceOnCooldown else { return state }

        // Open the invulnerability window and start the Brace cooldown.
        // Parry detection (enemy attack landing during window) is handled in advanceTimers.
        return state
            .withBraceWindowTimer(state.config.braceWindowDuration)
            .withBraceCooldownTimer(state.config.braceCooldownSeconds)
    }

    // MARK: - Special

    private static let specialAttackDamage = 60
    private static let dashAdvanceSquares = 3

    private static func applySpecial(to state: GameState) -> GameState {
        guard case .combat(var encounter) = state.screenMode else { return state }
        guard state.specialIsReady else { return state }

        encounter.enemyHP -= specialAttackDamage

        let next = state
            .withSpecialCharge(0.0)
            .withTransientOverlay(.special(framesRemaining: TransientOverlay.defaultDuration))
        if encounter.enemyHP <= 0 {
            let floor = FloorRegistry.floor(state.currentFloor, config: state.config)
            if let encounterPos = floor.encounterPosition2D {
                var cleared = next.clearedEncounterPositions
                cleared.insert(encounterPos)
                return next
                    .withClearedEncounterPositions(cleared)
                    .withScreenMode(.dungeon)
            }
            return next.withScreenMode(.dungeon)
        }
        return next.withScreenMode(.combat(encounter: encounter))
    }

    // MARK: - Overlay confirmation

    private static func applyConfirmOverlay(to state: GameState) -> GameState {
        guard case .narrativeOverlay(let event) = state.screenMode else { return state }

        switch event {
        case .eggDiscovery:
            return state.withHasEgg(true).withScreenMode(.dungeon)
        case .exitPatio:
            return state.withScreenMode(.winState)
        case .specialAttack:
            return state.withScreenMode(.dungeon)
        }
    }

    // MARK: - Upgrade selection

    private static func applyUpgrade(_ upgrade: Upgrade, to state: GameState) -> GameState {
        var newConfig = state.config
        applyEffect(upgrade.effect, to: &newConfig)
        let newUpgrades = state.activeUpgrades + [upgrade]
        let capGain = newConfig.dashChargeCap - state.config.dashChargeCap
        let newDashCharges = min(state.dashCharges + capGain, newConfig.dashChargeCap)
        let hpGain = newConfig.maxHP - state.config.maxHP
        let newHP = min(state.hp + hpGain, newConfig.maxHP)
        return state
            .withConfig(newConfig)
            .withActiveUpgrades(newUpgrades)
            .withDashCharges(newDashCharges)
            .withHP(newHP)
            .withScreenMode(.dungeon)
    }

    private static func applyEffect(_ effect: UpgradeEffect, to config: inout GameConfig) {
        switch effect {
        case .reduceDashCooldown(let factor):
            config.dashCooldownSeconds *= factor
        case .increaseDashChargeCap(let n):
            config.dashChargeCap += n
            config.dashStartingCharges += n
        case .increaseMaxHP(let n):
            config.maxHP += n
        case .increaseSpecialRate(let factor):
            config.specialChargeRatePerSecond *= factor
        }
    }

}
