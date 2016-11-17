module falcor.router;

import falcor.hashtable;
import falcor.types;

class Router {
	HashTable ht;
	this() {

	}

	void insert(string path, Callback cb) {
		this.ht.insert(StrDel(path, cb));
		this.ht.rebuildHashes();
	}
}
