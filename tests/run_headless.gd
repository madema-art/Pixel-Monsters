extends SceneTree

func _initialize() -> void:
	call_deferred("run_tests")

func run_tests() -> void:
	var suite: McpTestSuite = load("res://tests/test_destruction.gd").new()
	var results: Array[Dictionary]=[]
	var failed := 0
	for method in suite.get_method_list():
		if not method.name.begins_with("test_"): continue
		suite._reset()
		suite.setup()
		suite.call(method.name)
		results.append({"test":method.name,"passed":not suite._failed,"assertions":suite._assertion_count,"message":suite._message})
		if suite._failed: failed+=1
		suite.teardown()
		suite._free_tracked()
	var report := {"total":results.size(),"failed":failed,"passed":results.size()-failed,"results":results,"fresh_process":true}
	var file := FileAccess.open("res://docs/headless-tests.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	print(JSON.stringify(report))
	quit(1 if failed else 0)
