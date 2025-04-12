extends Node

func async_request(url: String, custom_headers := PackedStringArray(), method := HTTPClient.Method.METHOD_GET, request_data := "") -> HTTPResult:
	var new_requester := HTTPRequest.new()
	add_child(new_requester)
	new_requester.timeout = 5.0
	var err := new_requester.request(url, custom_headers, method, request_data)
	if err:
		new_requester.queue_free()
		return HTTPResult._from_error(err)

	var result := await new_requester.request_completed as Array
	
	new_requester.queue_free()

	return HTTPResult._from_array(result)
