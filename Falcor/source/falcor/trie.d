module falcor.trie;

struct TrieNode {
	char character;
	size_t[52] follow;
	size_t end;

	this(char character) {
		this.character = character;
		this.follow[] = size_t.max;
		this.end = size_t.max;
	}
}

unittest {
	pragma(msg, cast(float)(TrieNode.sizeof) / 1024);
}

struct Trie {
	import std.array : empty;
	import std.container.array : Array;

	Array!(TrieNode) trie;
	size_t[52] roots = size_t.max;

	size_t insert(string str) {
		import std.exception : enforce;
		enforce(!str.empty);

		if(this.roots[str[0]] == size_t.max) {
			this.roots[str[0]] = trie.length;
			this.trie.insertBack(TrieNode(str[0]));
		}

		return 0;
	}
}

unittest {
	Trie trie;
	foreach(it; trie.roots) {
		assert(it == size_t.max);
	}
}
