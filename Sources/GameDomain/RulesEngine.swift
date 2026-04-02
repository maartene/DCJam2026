// RulesEngine — pure function driving port: (GameState, GameCommand, deltaTime) → GameState.
// All game rules live here. No I/O, no side effects.

enum RulesEngine {

    static func apply(command: GameCommand, to state: GameState, deltaTime: Double) -> GameState {
        // Advance timers first on every tick.
        let next = advanceTimers(state, deltaTime: deltaTime)

        switch command {
        case .none:
            return next

        case .move(let direction):
            return applyMove(direction, to: next)

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

        var next = state
            .withTimerModel(newTimerModel)
            .withDashCharges(newCharges)
            .withSpecialCharge(newSpecial)
            .withBraceWindowTimer(newBraceWindow)
            .withBraceCooldownTimer(newBraceCooldown)

        // Enemy attack timer fires only in combat.
        if case .combat(var encounter) = next.screenMode {
            encounter.enemyAttackTimer -= deltaTime
            if encounter.enemyAttackTimer <= 0 {
                // Timer fired: deal damage or absorb with Brace.
                if braceWasActive {
                    // Parry — absorb hit, zero HP damage.
                    encounter.enemyAttackTimer = next.config.enemyAttackInterval
                    next = next.withScreenMode(.combat(encounter: encounter))
                } else {
                    // Full unbraced hit.
                    let damage = encounterBaseDamage(encounter)
                    let newHP = max(next.hp - damage, 0)
                    encounter.enemyAttackTimer = next.config.enemyAttackInterval
                    next = next.withHP(newHP).withScreenMode(.combat(encounter: encounter))
                    if newHP == 0 {
                        next = next.withScreenMode(.deathState)
                    }
                }
            } else {
                next = next.withScreenMode(.combat(encounter: encounter))
            }
        }

        return next
    }

    // MARK: - Movement

    private static func applyMove(_ direction: MoveDirection, to state: GameState) -> GameState {
        // Movement is locked when in combat — only Dash exits an encounter.
        if case .combat = state.screenMode {
            return state
        }

        guard direction == .forward else { return state }

        let newPos = state.playerPosition + 1
        let floor = FloorGenerator.generate(floorNumber: state.currentFloor, config: state.config)

        // Descend staircase.
        if newPos >= floor.staircasePosition && !floor.hasExitSquare {
            let nextFloor = state.currentFloor + 1
            let nextFloorMap = FloorGenerator.generate(floorNumber: nextFloor, config: state.config)
            return state.withCurrentFloor(nextFloor).withPlayerPosition(nextFloorMap.entryPosition)
        }

        // Step onto exit square (requires egg for win).
        if floor.hasExitSquare && newPos >= floor.exitPosition {
            if state.hasEgg {
                return state
                    .withPlayerPosition(newPos)
                    .withScreenMode(.narrativeOverlay(event: .exitPatio))
            }
            return state.withPlayerPosition(newPos)
        }

        // Step into egg room.
        if floor.hasEggRoom, let eggPos = floor.eggRoomPosition, newPos >= eggPos, !state.hasEgg {
            return state
                .withPlayerPosition(newPos)
                .withScreenMode(.narrativeOverlay(event: .eggDiscovery))
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
            .withPlayerPosition(state.playerPosition + 3)
            .withScreenMode(.dungeon)
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

    private static func applySpecial(to state: GameState) -> GameState {
        guard case .combat(var encounter) = state.screenMode else { return state }
        guard state.specialIsReady else { return state }

        let specialDamage = 60
        encounter.enemyHP -= specialDamage

        let next = state.withSpecialCharge(0.0)
        if encounter.enemyHP <= 0 {
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
        return state
            .withConfig(newConfig)
            .withActiveUpgrades(newUpgrades)
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

    // MARK: - Helpers

    private static func encounterBaseDamage(_ encounter: EncounterModel) -> Int {
        encounter.isBossEncounter ? 25 : 15
    }
}
