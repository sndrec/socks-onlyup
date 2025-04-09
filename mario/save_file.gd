class_name MarioSaveFile extends Resource

const current_version : String = "v0.1"

var save_pos := Vector3.ZERO
var save_angle := 0.0
var coins : int
var star_data : Array[StarSaveData]
var star_data_lookup : Dictionary

func try_add_star_data_entry(in_id : String, in_time : float, in_coins : int, in_num_checkpoints : int):
	#print("trying to add star data entry \"" + in_id + "\"")
	if star_data_lookup.has(in_id):
		#print("we have this star id already in this block")
		#save block has this star
		if in_time < star_data[star_data_lookup[in_id]].time:
			#print("that being said, this submission has a faster time, so let's update it")
			#new time for this star is faster, so assign it to existing star data
			star_data[star_data_lookup[in_id]].time = in_time
		if in_num_checkpoints < star_data[star_data_lookup[in_id]].checkpoints_used:
			star_data[star_data_lookup[in_id]].checkpoints_used = in_num_checkpoints
	else:
		#print("we don't have this star submitted yet, so let's add it")
		var new_data := StarSaveData.new()
		new_data.star_id = in_id
		#save block does not have this star,
		#so set time on new star data and add it to the save block
		new_data.time = in_time
		new_data.checkpoints_used = in_num_checkpoints
		star_data_lookup[in_id] = star_data.size()
		star_data.append(new_data)
	
	#did we collect more coins this time?
	if in_coins > coins:
		#print("this star also has more coins, so let's update the coin count on this block")
		#yes, assign new coin value
		coins = in_coins

func get_star_data(in_id : String) -> StarSaveData:
	if star_data_lookup.has(in_id):
		return star_data[star_data_lookup[in_id]]
	else:
		return null

func save_game():
	var save_bytes := StreamPeerBuffer.new()
	var save = FileAccess.open("user://infinite_mario_save.dat", FileAccess.WRITE)
	save.store_buffer(save_bytes.data_array)

func load_game():
	if not FileAccess.file_exists("user://infinite_mario_save.dat"):
		return
	var backup_save = FileAccess.open("user://infinite_mario_save_backup.dat", FileAccess.WRITE)
	var file_bytes : PackedByteArray = FileAccess.get_file_as_bytes("user://infinite_mario_save.dat")
	backup_save.store_buffer(file_bytes)
	backup_save.close()
	var save = FileAccess.open("user://infinite_mario_save.dat", FileAccess.READ)
	var version_string_length : int = save.get_32()
	var in_version = save.get_buffer(version_string_length).get_string_from_utf8()
	match in_version:
		"v0.1":
			var backup_save_01 = FileAccess.open("user://infinite_mario_save_v01_backup.dat", FileAccess.WRITE)
			backup_save_01.store_buffer(file_bytes)
			backup_save_01.close()

func get_total_star_count():
	return star_data.size()

func get_total_coin_coint():
	return coins

# star identifiers:
# "main" - the main level star
# "coin" - spawned when the player collects min(100, total_coins * 0.95) coins
# "red" - spawned when the player collects all red coins
# "cork" - chance to be spawned by a random cork block in the level

func is_star_collected(in_star_id : String) -> bool:
	return star_data_lookup.has(in_star_id)
