extends Node
class_name OpenAIClient

const BASE_URL = "https://mutiny-zhne.onrender.com"  # Change this to your server
var http_request: HTTPRequest
var game_token: String = ""

signal response_received(text: String)
signal error_occurred(error: String)
func _init():
	http_request = HTTPRequest.new()
	add_child(http_request)

func _ready():
	http_request.request_completed.connect(_on_response_completed)
	_load_or_generate_token()

func _load_or_generate_token() -> void:
	# Try to load existing token
	var config = ConfigFile.new()
	var err = config.load("user://game_token.cfg")
	
	if err == OK:
		game_token = config.get_value("auth", "token", "")
		if not game_token.is_empty():
			return
	
	# If no token exists, generate new one
	_generate_new_token()

func _generate_new_token() -> void:
	var headers = ["Content-Type: application/json"]
	var error = http_request.request(
		BASE_URL + "/generate-token",
		headers,
		HTTPClient.METHOD_POST,
		"{}"
	)
	if error != OK:
		print("ERROR")
		print(error)
		emit_signal("error_occurred", "Failed to generate token")

func _save_token(token: String) -> void:
	var config = ConfigFile.new()
	config.set_value("auth", "token", token)
	config.save("user://game_token.cfg")
	game_token = token

func send_message(message: String) -> void:
	print("getting game token...")
	if game_token.is_empty():
		print("Token is empty")
		emit_signal("error_occurred", "No auth token available")
		return
		
	var headers = [
		"Content-Type: application/json",
		"X-Game-Token: " + game_token
	]
	
	print("sending message...")
	
	var body = {"message": message}
	var json_string = JSON.stringify(body)
	
	var error = http_request.request(
		BASE_URL + "/chat",
		headers,
		HTTPClient.METHOD_POST,
		json_string
	)
	
	if error != OK:
		emit_signal("error_occurred", "Failed to send message")

func _on_response_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	print("RESPONSE RECEIVED")
	var json = JSON.parse_string(body.get_string_from_utf8())
	
	if response_code != 200:
		print("response code was not 200")
		print(json)
		emit_signal("error_occurred", json.get("error", "Unknown error occurred"))
		return
		
	if "token" in json:
		print("RESPONSE TOKEN IS ")
		print(json["token"])
		_save_token(json["token"])
		return
		
	if "response" in json:
		emit_signal("response_received", json["response"])
		print("response:")
		print(json["response"])
		print("Requests remaining: ", json["requests_remaining"])
	else:
		print(json)
