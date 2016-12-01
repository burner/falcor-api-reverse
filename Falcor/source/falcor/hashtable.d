module falcor.hashtable;

import falcor.types;

import std.stdio;

struct HashTable {
	import falcor.hashfunctions;
	import std.container.array : Array;

	Array!StrDel routes;
	Array!size_t hashes;
	size_t primTablePtr = 1;
	HashFunction hashFunction;

	void insert(string path, Callback callback) {
		this.routes.insertBack(StrDel(path, callback));
	}

	final void clearHashes() {
		while(!this.hashes.empty) {
			this.hashes.removeBack();
		}
	}

	final void nullFill() {
		for(size_t i = 0; i < this.primTablePtr; ++i) {
			this.hashes.insertBack(size_t.max);
		}
	}

	bool testHashCombination() {
		this.clearHashes();
		this.nullFill();
		size_t idx = 0;
		foreach(ref it; this.routes) {
			const h = hash(it.path, this.hashFunction);
			const hmod = h % this.primTablePtr;
			if(this.hashes[hmod] != size_t.max) {
				return false;
			} else {
				this.hashes[hmod] = idx;
			}
			++idx;
		}
		return true;
	}

	void rebuildHashes() {
		foreach(hf; [HashFunction.Jenkins, HashFunction.Siphash,
				HashFunction.Murmur, HashFunction.XXhash])
		{
			this.hashFunction = hf;

			if(testHashCombination()) {
				return;
			}
			++this.primTablePtr;
		}
		assert(false);
	}
}

unittest {
	import std.stdio;
	writeln(__LINE__);
	auto strs = ["hello","hella", "world", "foobar"];
	HashTable ht;       
	foreach(str; strs) {
		ht.insert(str, null);
		ht.rebuildHashes();
		writefln("%s %s", ht.hashFunction, ht.hashes[]);
	}
}
