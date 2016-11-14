module falcor.hashtable;

import falcor.types;

import std.stdio;

private immutable(size_t[]) primTable = [
	2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71,
	73, 79, 83, 89, 97, 101, 103, 107, 109, 113, 127, 131, 137, 139, 149, 151,
	157, 163, 167, 173, 179, 181, 191, 193, 197, 199, 211, 223, 227, 229, 233,
	239, 241, 251, 257, 263, 269, 271, 277, 281, 283, 293, 307, 311, 313, 317,
	331, 337, 347, 349, 353, 359, 367, 373, 379, 383, 389, 397, 401, 409, 419,
	421, 431, 433, 439, 443, 449, 457, 461, 463, 467, 479, 487, 491, 499, 503,
	509, 521, 523, 541, 547, 557, 563, 569, 571, 577, 587, 593, 599, 601, 607,
	613, 617, 619, 631, 641, 643, 647, 653, 659, 661, 673, 677, 683, 691, 701,
	709, 719, 727, 733, 739, 743, 751, 757, 761, 769, 773, 787, 797, 809, 811,
	821, 823, 827, 829, 839, 853, 857, 859, 863, 877, 881, 883, 887, 907, 911,
	919, 929, 937, 941, 947, 953, 967, 971, 977, 983, 991, 997
];

struct HashTable {
	import falcor.hashfunctions;
	import std.container.array : Array;

	Array!StrDel routes;
	Array!size_t hashes;
	size_t primTablePtr = 0;
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
		for(size_t i = 0; i < primTable[this.primTablePtr]; ++i) {
			this.hashes.insertBack(size_t.max);
		}
	}

	bool testHashCombination() {
		this.clearHashes();
		this.nullFill();
		size_t idx = 0;
		foreach(ref it; this.routes) {
			const h = hash(it.path, this.hashFunction);
			const hmod = h % primTable[this.primTablePtr];
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
		while(this.primTablePtr < primTable.length) {
			foreach(hf; [HashFunction.Jenkins, HashFunction.Murmur,
					HashFunction.Siphash, HashFunction.XXhash])
			{
				this.hashFunction = hf;
				if(testHashCombination()) {
					return;
				}
			}
			++this.primTablePtr;
		}
		assert(false);
	}
}

unittest {
	import std.stdio;

	HashTable ht;
	ht.insert("hello", null);
	ht.insert("hella", null);
	ht.insert("world", null);
	ht.insert("foobar", null);
	ht.rebuildHashes();

	writeln(ht.hashes[]);
}
