class_name Inventory


var items: Dictionary = {} # {item_id: count}


func add(item_id: String, amount: int):
	items.get_or_add(item_id, 0)
	items[item_id] += amount


func remove(item_id: String, amount: int):
	if items.has(item_id):
		items[item_id] -= amount
		if items[item_id] < 1:
			items.erase(item_id)
