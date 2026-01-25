class_name Inventory


var items: Dictionary = {} # {item_id: count}

var max_stacksize: int = 1 # Currently this applies to every different item in the inventory

func add(item_id: String, amount: int):
	items.get_or_add(item_id, 0)
	if items[item_id] < max_stacksize:
		items[item_id] += amount


func remove(item_id: String, amount: int):
	if items.has(item_id):
		items[item_id] -= amount
		if items[item_id] < 1:
			items.erase(item_id)
