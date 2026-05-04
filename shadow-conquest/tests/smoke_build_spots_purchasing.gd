extends SceneTree

const MAIN_SCENE_PATH := "res://scenes/main.tscn"
const FIXTURE_INDEX_PATH := "res://tests/fixtures/scenario_index_fixture.json"

func _init() -> void:
	var failures: Array[String] = []

	if not ResourceLoader.exists(MAIN_SCENE_PATH):
		failures.append("Missing main scene at %s" % MAIN_SCENE_PATH)
	elif not FileAccess.file_exists(FIXTURE_INDEX_PATH):
		failures.append("Missing scenario index fixture at %s" % FIXTURE_INDEX_PATH)
	else:
		var packed_main := load(MAIN_SCENE_PATH) as PackedScene
		var main := packed_main.instantiate() as Node
		main.set("scenario_index_path", FIXTURE_INDEX_PATH)
		get_root().add_child(main)
		main.call("_ready")

		_validate_build_api(main, failures)
		if failures.is_empty():
			_validate_purchase_flow(main, failures)
			_validate_refused_purchases(main, failures)
			_validate_scenario_switch_reset(main, failures)

		main.free()
		if failures.is_empty():
			_validate_hud_purchase_flow(failures)

	if failures.is_empty():
		print("smoke_build_spots_purchasing: ok")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _validate_build_api(main: Node, failures: Array[String]) -> void:
	for method_name in [
		"build_tower_at_spot",
		"get_build_gold",
		"get_available_build_spots",
		"get_tower_build_options",
	]:
		if not main.has_method(method_name):
			failures.append("Main must expose %s()" % method_name)

	if main.get_node_or_null("BuildStateAdapter") == null:
		failures.append("Main scene must include BuildStateAdapter")
	if main.get_node_or_null("World/BuildSpots") == null:
		failures.append("Main scene must include World/BuildSpots")

func _validate_purchase_flow(main: Node, failures: Array[String]) -> void:
	var tower_root := main.get_node_or_null("World/Towers")
	var attack_adapter := main.get_node_or_null("TowerAttackAdapter")
	if tower_root == null:
		failures.append("Main scene must include World/Towers")
		return
	if attack_adapter == null or not attack_adapter.has_method("get_registered_tower_count"):
		failures.append("Main scene must include TowerAttackAdapter.get_registered_tower_count()")
		return

	var start_tower_count := tower_root.get_child_count()
	var start_registered_count := int(attack_adapter.call("get_registered_tower_count"))
	var start_gold := int(main.call("get_build_gold"))
	var start_spots := main.call("get_available_build_spots") as Array
	var tower_options := main.call("get_tower_build_options") as Array
	if start_gold != 100:
		failures.append("Fixture map one should start with 100 build gold")
	if start_spots.size() != 1:
		failures.append("Fixture map one should expose exactly one available build spot after prebuilt occupancy")
	if tower_options.size() < 2:
		failures.append("Fixture map one should expose buildable tower options")
	if start_spots.is_empty():
		return

	var spot := start_spots[0] as Dictionary
	var spot_id := str(spot.get("id", ""))
	if spot_id != "fixture-open-spot":
		failures.append("Fixture map one should expose fixture-open-spot as the available spot")

	if not bool(main.call("build_tower_at_spot", spot_id, "fixture-eye")):
		failures.append("Main should accept a valid affordable purchase")
	if tower_root.get_child_count() != start_tower_count + 1:
		failures.append("Successful purchase must spawn one tower under World/Towers")
	if int(attack_adapter.call("get_registered_tower_count")) != start_registered_count + 1:
		failures.append("Successful purchase must register the tower with TowerAttackAdapter")
	if int(main.call("get_build_gold")) != start_gold - 40:
		failures.append("Successful purchase must spend the tower cost")
	if (main.call("get_available_build_spots") as Array).size() != start_spots.size() - 1:
		failures.append("Successful purchase must remove the used spot from available spots")

func _validate_refused_purchases(main: Node, failures: Array[String]) -> void:
	var tower_root := main.get_node_or_null("World/Towers")
	var attack_adapter := main.get_node_or_null("TowerAttackAdapter")
	if tower_root == null or attack_adapter == null:
		return

	var tower_count := tower_root.get_child_count()
	var registered_count := int(attack_adapter.call("get_registered_tower_count"))
	var gold := int(main.call("get_build_gold"))

	if bool(main.call("build_tower_at_spot", "fixture-open-spot", "fixture-eye")):
		failures.append("Main must refuse duplicate purchase on an occupied spot")
	if bool(main.call("build_tower_at_spot", "missing-spot", "fixture-eye")):
		failures.append("Main must refuse unknown build spots")
	if bool(main.call("build_tower_at_spot", "fixture-open-spot", "missing-tower")):
		failures.append("Main must refuse unknown tower types")

	if tower_root.get_child_count() != tower_count:
		failures.append("Refused purchases must not spawn towers")
	if int(attack_adapter.call("get_registered_tower_count")) != registered_count:
		failures.append("Refused purchases must not register towers")
	if int(main.call("get_build_gold")) != gold:
		failures.append("Refused purchases must not spend gold")

func _validate_scenario_switch_reset(main: Node, failures: Array[String]) -> void:
	if not bool(main.call("load_scenario_by_id", "fixture-map-2")):
		failures.append("Main must switch to fixture-map-2")
		return

	if int(main.call("get_build_gold")) != 25:
		failures.append("Scenario switch must reset build gold from the new scenario")
	var spots := main.call("get_available_build_spots") as Array
	if spots.size() != 1:
		failures.append("Scenario switch must reset available build spots")
	elif str((spots[0] as Dictionary).get("id", "")) != "fixture-map-2-spot":
		failures.append("Scenario switch must expose the second fixture build spot")

	var tower_root := main.get_node_or_null("World/Towers")
	var attack_adapter := main.get_node_or_null("TowerAttackAdapter")
	if tower_root == null or attack_adapter == null:
		return
	var tower_count := tower_root.get_child_count()
	var registered_count := int(attack_adapter.call("get_registered_tower_count"))
	var gold := int(main.call("get_build_gold"))
	if bool(main.call("build_tower_at_spot", "fixture-map-2-spot", "fixture-eye")):
		failures.append("Main must refuse unaffordable purchases")
	if tower_root.get_child_count() != tower_count:
		failures.append("Unaffordable purchase must not spawn a tower")
	if int(attack_adapter.call("get_registered_tower_count")) != registered_count:
		failures.append("Unaffordable purchase must not register a tower")
	if int(main.call("get_build_gold")) != gold:
		failures.append("Unaffordable purchase must not spend gold")

func _validate_hud_purchase_flow(failures: Array[String]) -> void:
	var packed_main := load(MAIN_SCENE_PATH) as PackedScene
	var main := packed_main.instantiate() as Node
	main.set("scenario_index_path", FIXTURE_INDEX_PATH)
	get_root().add_child(main)
	main.call("_ready")

	var hud := main.get_node_or_null("HUD")
	var tower_root := main.get_node_or_null("World/Towers")
	if hud == null:
		failures.append("HUD purchase flow requires HUD")
		main.free()
		return
	if tower_root == null:
		failures.append("HUD purchase flow requires World/Towers")
		main.free()
		return
	var start_failure_count := failures.size()
	for method_name in ["bind_build_state", "active_build_spot_id", "active_tower_type_id"]:
		if not hud.has_method(method_name):
			failures.append("HUD purchase flow requires HUD.%s()" % method_name)
	if not hud.has_signal("build_requested"):
		failures.append("HUD purchase flow requires build_requested signal")
	if failures.size() > start_failure_count:
		main.free()
		return

	var start_gold := int(main.call("get_build_gold"))
	var start_spots := main.call("get_available_build_spots") as Array
	var start_tower_count := tower_root.get_child_count()
	var spot_select := hud.get_node_or_null("HudBar/BuildSpotSelect") as OptionButton
	var tower_select := hud.get_node_or_null("HudBar/TowerTypeSelect") as OptionButton
	var gold_value := hud.get_node_or_null("HudBar/GoldValue") as Label
	var build_button := hud.get_node_or_null("HudBar/BuildButton") as Button
	if spot_select == null or tower_select == null or gold_value == null or build_button == null:
		failures.append("HUD purchase flow requires build controls under HudBar")
		main.free()
		return

	if gold_value.text != str(start_gold):
		failures.append("HUD GoldValue must be bound during Main._ready")
	if str(hud.call("active_build_spot_id")) != "fixture-open-spot":
		failures.append("HUD must select the available fixture build spot after Main._ready")
	if str(hud.call("active_tower_type_id")) != "fixture-eye":
		failures.append("HUD must select the first fixture tower option after Main._ready")

	build_button.emit_signal("pressed")
	if tower_root.get_child_count() != start_tower_count + 1:
		failures.append("HUD BuildButton must purchase and spawn a tower through Main")
	if int(main.call("get_build_gold")) != start_gold - 40:
		failures.append("HUD build purchase must refresh Main build gold")
	if (main.call("get_available_build_spots") as Array).size() != start_spots.size() - 1:
		failures.append("HUD build purchase must remove the used spot from available spots")
	if gold_value.text != str(start_gold - 40):
		failures.append("HUD GoldValue must refresh after HUD build attempt")
	if spot_select.item_count != start_spots.size() - 1:
		failures.append("HUD BuildSpotSelect must refresh after HUD build attempt")

	main.free()
