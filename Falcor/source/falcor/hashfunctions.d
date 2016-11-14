module falcor.hashfunctions;

uint jenkins_one_at_a_time_hash(string key) {
    uint hash = 0;
    for(size_t i = 0; i < key.length; ++i) {
        hash += key[i];
        hash += (hash << 10);
        hash ^= (hash >> 6);
    }
    hash += (hash << 3);
    hash ^= (hash >> 11);
    hash += (hash << 15);
    return hash;
}

unittest {
	assert(jenkins_one_at_a_time_hash("hello") ==
			jenkins_one_at_a_time_hash("hello"));
}


import falcor.types : HashFunction;

uint hash(const(string) s, HashFunction hf) {
	import murmurhash3;
	import siphash;
	import xxhash;

	final switch(hf) {
		case HashFunction.Jenkins:
			return jenkins_one_at_a_time_hash(s);
		case HashFunction.Murmur:
			return murmurHash3_x86_32(cast(ubyte[])s, 0);
		case HashFunction.Siphash:
			const(ubyte[16]) key = cast(ubyte[16])"super secret ke";
			return cast(uint)(siphash24Of(key, cast(ubyte[])s) % uint.max);
		case HashFunction.XXhash:
			return xxhashOf(cast(ubyte[])s, 0);
	}
}

unittest {
	import std.stdio;

	string[] keys = ["Hello", "World", "Dlang", "unittest", "foobar"];

	foreach(key; keys) {
		foreach(hf; [HashFunction.Jenkins, HashFunction.Murmur,
				HashFunction.Siphash, HashFunction.XXhash])
		{
			writefln("%10s %10s %10d", key, hf, hash(key, hf));
		}
	}
}
