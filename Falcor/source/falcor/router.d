module falcor.router;

import vibe.data.json;

import falcor.hashtable;
import falcor.types;

struct Range {
	Json[] values;
	ptrdiff_t low;
	ptrdiff_t high;
	
	this(Json value) {
		if(value.type == Json.Type.array) {
			this.values = value.get!(Json[])();
		} else {
			Json[1] tmp;
			tmp[0] = value;
			this.values = Json(tmp[]).get!(Json[])();
		}

		this.low = 0;
		this.high = this.values.length - 1;
	}

	@property Json front() {
		return this.values[this.low];
	}

	@property Json back() {
		return this.values[this.high];
	}

	@property bool empty() const {
		return this.low > this.high;
	}

	void popFront() {
		++this.low;
	}

	void popBack() {
		--this.high;
	}
}

enum IntegerType {
	FromTo,
	Values
}

struct Integers {
	IntegerType type;
	Json value;

	Range getBidirectionalRange() {
		return Range(this.value);
	}
}

struct Strings {
	Json value;

	Range getBidirectionalRange() {
		return Range(this.value);
	}
}

struct Get {
	string path;
}

class Router {
	//HashTable ht;
	this() {

	}

	void registerRoute(alias Fun)() {
	}

/*
users
	{integer}
		username 		-> userNameHash
		passwordHash	-> userNameHash

		firstname 		-> userFirstLastEmail
		lastname		-> userFirstLastEmail
		email			-> userFirstLastEmail


users[0,4,2].[username,passwordHash,email]

	users[0,4,2].[username,passwordHash]
	users[0,4,2].[email]


## Grammar

Start   := string Follow?
String  := . string Follow?
Strings := [(identifier:)? string (, string)*] Follow?
Integer := [(identifier:)? long (, long)*] Follow?
Follow  := String | Strings | Integer 

## Idea

Parse JSONValue Path into Grammar-List as shown above then match against
Grammar-Trie of all methods
*/

	@Get("users[ids:{integer}].[attri: username, passwordHash]")
	void userNameHash(
		ref Json requestPath,
		ref Json retValues, ref Json retPaths, 
		Integers ids, Strings attri)
	{

	}

	@Get("users[ids:{integer}].[attri: firstname, lastname, email]")
	void userFirstLastEmail(
		ref Json requestPath,
		ref Json retValues, ref Json retPaths, 
		Integers ids, Strings attri)
	{

	}

	//void insert(string path, Callback cb) {
	//	this.ht.insert(StrDel(path, cb));
	//	this.ht.rebuildHashes();
	//}
}
