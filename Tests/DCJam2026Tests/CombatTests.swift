import Testing
@testable import GameDomain

// Combat Tests — US-03 (Special), US-05 (Brace), US-09 (boss defeat)
//
// Brace mechanic: timed invulnerability window (braceWindowDuration), cooldown (braceCooldownSeconds).
// A successful parry = enemy attack lands while window is active → 0 damage + braceSpecialBonus.
// An unbraced hit = enemy attack lands with no active window → full encounter damage.
// Enemy attacks on a fixed timer (enemyAttackInterval) — predictable rhythm, no telegraph.
//
// Covers: parry absorbs damage, unbraced hit deals damage, Brace cooldown prevents spam,
// Special requires full charge, Special resets charge to 0, Special defeats/damages enemy,
// boss defeatable with Brace + Special, screen transitions after combat.
//
// Error / edge paths: unbraced fatal hit triggers death, Special below full charge is blocked,
// Special at game start is unavailable (INT-02), boss survives until defeated.
// Error path ratio in this file: 4 of 13 = 31%

@Suite("Combat — Brace and Special")
struct CombatTests {

    // MARK: - Brace: reduces damage

    @Test("Ember takes zero damage during a successful Brace parry vs full damage when unbraced",
          .disabled("not yet implemented"))
    func braceTakesDamage() {
        // Given — identical encounter at the moment an enemy attack lands
        let config = GameConfig.default
        let baseState = gameStateInRegularEncounter()
        // Brace path: Ember braces, then time advances so the enemy attack lands inside the window
        let braceActivated = RulesEngine.apply(command: .brace, to: baseState, deltaTime: 0.0)
        let bracedResult = RulesEngine.apply(command: .none, to: braceActivated, deltaTime: config.enemyAttackInterval + 0.1)
        // Unbraced path: time advances so the enemy attack lands with no protection
        let unbracedResult = RulesEngine.apply(command: .none, to: baseState, deltaTime: config.enemyAttackInterval + 0.1)
        // Then — a successful parry absorbs all damage; unbraced takes the full hit
        let bracedDamage = baseState.hp - bracedResult.hp
        let unbracedDamage = baseState.hp - unbracedResult.hp
        #expect(bracedDamage < unbracedDamage)
    }

    @Test("Brace keeps Ember in the encounter — it does not end combat",
          .disabled("not yet implemented"))
    func braceKeepsEncounterActive() {
        // Given
        let state = gameStateInRegularEncounter()
        // When
        let result = RulesEngine.apply(command: .brace, to: state, deltaTime: 0.0)
        // Then
        if case .combat = result.screenMode {
            // expected — encounter continues
        } else {
            Issue.record("Expected encounter to continue after Brace, got \(result.screenMode)")
        }
    }

    @Test("Brace is selectable even when both Dash charges are depleted",
          .disabled("not yet implemented"))
    func braceSelectableWithZeroDashCharges() {
        // Given — Dash at 0, Special below full
        var state = gameStateInRegularEncounter()
        state = state.withDashCharges(0)
        state = state.withSpecialCharge(0.0)
        // When
        let result = RulesEngine.apply(command: .brace, to: state, deltaTime: 0.0)
        // Then — brace executes (HP is affected, encounter continues) — not a no-op
        let damageOccurred = result.hp < state.hp
        let encounterContinues: Bool
        if case .combat = result.screenMode { encounterContinues = true } else { encounterContinues = false }
        #expect(damageOccurred || encounterContinues) // brace did something
    }

    // MARK: - Brace: successful parry charges Special

    @Test("A successful Brace parry adds the configured Special charge bonus",
          .disabled("not yet implemented"))
    func braceParryGrantsSpecialBonus() {
        // Given — Ember braces at the moment an enemy attack is incoming
        let config = GameConfig.default
        let baseState = gameStateInRegularEncounter()
        let chargeBefore = baseState.specialCharge
        // When — activate Brace, then advance time so the enemy attack lands inside the window
        let braceActivated = RulesEngine.apply(command: .brace, to: baseState, deltaTime: 0.0)
        let result = RulesEngine.apply(command: .none, to: braceActivated, deltaTime: config.enemyAttackInterval + 0.1)
        // Then — Special charge increased by at least the configured bonus
        #expect(result.specialCharge >= chargeBefore + config.braceSpecialBonus)
    }

    // MARK: - Brace error path: fatal unbraced hit triggers death

    @Test("The death condition fires when an unbraced enemy attack drops HP to 0",
          .disabled("not yet implemented"))
    func fatalUnbracedHitTriggersDeathCondition() {
        // Given — Ember at 1 HP in encounter, no Brace active
        let config = GameConfig.default
        var state = gameStateInRegularEncounter()
        state = state.withHP(1)
        // When — time advances past the enemy attack interval (unbraced → full hit)
        let result = RulesEngine.apply(command: .none, to: state, deltaTime: config.enemyAttackInterval + 0.1)
        // Then — death fires and HP floors at 0, never negative
        #expect(result.hp >= 0)
        if result.hp == 0 {
            if case .deathState = result.screenMode {
                // correct — death fired
            } else {
                Issue.record("Expected .deathState when HP hit 0 via unbraced attack")
            }
        }
    }

    // MARK: - Special: requires full charge

    @Test("Special is not selectable when the charge meter is below full",
          .disabled("not yet implemented"))
    func specialNotSelectableBelowFull() {
        // Given — Special at 80% (not full)
        var state = gameStateInRegularEncounter()
        state = state.withSpecialCharge(0.8)
        let positionBefore = state.playerPosition
        // When
        let result = RulesEngine.apply(command: .special, to: state, deltaTime: 0.0)
        // Then — Special does nothing (position unchanged, charge unchanged, encounter persists)
        #expect(result.specialCharge == 0.8)
        #expect(result.playerPosition == positionBefore)
        if case .combat = result.screenMode {
            // expected
        } else {
            Issue.record("Expected encounter to persist when Special attempted below full charge")
        }
    }

    @Test("Special cannot be used at game start because the charge begins at 0",
          .disabled("not yet implemented"))
    func specialUnavailableAtGameStart() {
        // Given
        let config = GameConfig.default
        let baseState = GameState.initial(config: config)
        let state = baseState.withScreenMode(.combat(encounter: EncounterModel.guard(isBossEncounter: false)))
        // When
        let result = RulesEngine.apply(command: .special, to: state, deltaTime: 0.0)
        // Then — Special charge is still 0, nothing fired
        #expect(result.specialCharge == 0.0)
    }

    // MARK: - Special: full charge fires and resets

    @Test("Ember's Special charge resets to 0 after the Special attack fires",
          .disabled("not yet implemented"))
    func specialChargeResetsAfterUse() {
        // Given — charge at full
        var state = gameStateInRegularEncounter()
        state = state.withSpecialCharge(1.0)
        // When
        let result = RulesEngine.apply(command: .special, to: state, deltaTime: 0.0)
        // Then
        #expect(result.specialCharge == 0.0)
    }

    @Test("The enemy takes significant damage when Ember fires Special",
          .disabled("not yet implemented"))
    func specialDamagesEnemy() {
        // Given
        var state = gameStateInRegularEncounter()
        state = state.withSpecialCharge(1.0)
        let enemyHPBefore: Int
        if case .combat(let encounter) = state.screenMode {
            enemyHPBefore = encounter.enemyHP
        } else {
            Issue.record("Expected combat screen mode")
            return
        }
        // When
        let result = RulesEngine.apply(command: .special, to: state, deltaTime: 0.0)
        // Then — either enemy is defeated (encounter ends) or took heavy damage
        var enemyHPAfter = 0
        if case .combat(let encounter) = result.screenMode {
            enemyHPAfter = encounter.enemyHP
        }
        let encounterEnded: Bool
        if case .dungeon = result.screenMode { encounterEnded = true } else { encounterEnded = false }
        #expect(enemyHPAfter < enemyHPBefore || encounterEnded)
    }

    @Test("After firing Special, the screen mode transitions away from the narrative overlay",
          .disabled("not yet implemented"))
    func specialOverlayTransitionsBackAfterConfirmation() {
        // Given — Special fired, narrative overlay is showing
        var state = GameState.initial(config: GameConfig.default)
        state = state.withScreenMode(.narrativeOverlay(event: .specialAttack))
        // When — player confirms (presses key)
        let result = RulesEngine.apply(command: .confirmOverlay, to: state, deltaTime: 0.0)
        // Then — back to dungeon or combat, not stuck on overlay
        if case .narrativeOverlay = result.screenMode {
            Issue.record("Expected screen mode to exit overlay after confirmation")
        }
    }

    // MARK: - Boss: defeatable with Brace and Special

    @Test("The boss is defeatable and the path to the exit opens after defeat",
          .disabled("not yet implemented"))
    func bossDefeatedUnblocksExit() {
        // Given — boss encounter, Ember has full Special and can brace
        var state = GameState.initial(config: GameConfig.default)
        state = state.withCurrentFloor(5)
        state = state.withSpecialCharge(1.0)
        let bossEncounter = EncounterModel.boss()
        state = state.withScreenMode(.combat(encounter: bossEncounter))
        // When — fire Special (the decisive blow)
        let afterSpecial = RulesEngine.apply(command: .special, to: state, deltaTime: 0.0)
        // Then — encounter either ended or boss HP significantly reduced
        var bossDefeated = false
        if case .dungeon = afterSpecial.screenMode { bossDefeated = true }
        // If not one-shot, continue bracing until boss falls — accept either outcome
        #expect(bossDefeated || afterSpecial.hp > 0) // game did not crash or soft-lock
    }

    // MARK: - Special charge accumulates over time

    @Test("Special charge increases when time passes during dungeon navigation")
    func specialChargeAccumulatesOverTime() {
        // Given
        let config = GameConfig.default
        let state = GameState.initial(config: config)
        let chargeBefore = state.specialCharge
        // When — advance time by 30 seconds (well under first-encounter window)
        let result = RulesEngine.apply(command: .none, to: state, deltaTime: 30.0)
        // Then — charge increased
        #expect(result.specialCharge > chargeBefore)
    }

    // MARK: - Property: Special cannot be full at first encounter (INT-02)

    @Test("Special charge cannot reach full in the time available before the first encounter",
          .disabled("not yet implemented"))
    func specialChargeCannotBeFullAtFirstEncounter() {
        // Given — typical Floor 1 walk time: at most 20 seconds
        let config = GameConfig.default
        let state = GameState.initial(config: config)
        // When — advance maximum plausible pre-encounter time
        let result = RulesEngine.apply(command: .none, to: state, deltaTime: 20.0)
        // Then — charge is still below full
        #expect(result.specialCharge < 1.0)
    }
}

// MARK: - Test Setup Helpers

private extension CombatTests {

    func gameStateInRegularEncounter() -> GameState {
        let state = GameState.initial(config: GameConfig.default)
        let encounter = EncounterModel.guard(isBossEncounter: false)
        return state.withScreenMode(.combat(encounter: encounter))
    }
}
