module falcor.types;

enum HashFunction {
	Siphash,
	Jenkins,
	Murmur,
	XXhash,
	SimdJenkins,
	Spooky,
}

enum Method {
	Get,
	Set,
	Call
}

/*struct StrDel {
	string path;
	Callback callback;
}

alias Callback = void delegate(JSONValue completePath, size_t offset, Method method,
				JSONValue arguments);
*/

