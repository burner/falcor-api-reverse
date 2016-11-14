module falcor.types;

import stdx.data.json.value;

enum HashFunction {
	Jenkins,
	Murmur,
	Siphash,
	XXhash,
}

enum Method {
	Get,
	Set,
	Call
}

struct StrDel {
	string path;
	Callback callback;
}

alias Callback = void delegate(JSONValue completePath, size_t offset, Method method,
				JSONValue arguments);

