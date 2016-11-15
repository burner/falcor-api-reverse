module falcor.hashfunctions;

uint jenkins_one_at_a_time_hash(const(string) key) {
    uint hash = 0;
	immutable len = key.length;
    for(size_t i = 0; i < len; ++i) {
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
	import falcor.spookyhash;

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
		case HashFunction.Spooky:
			return spooky_hash32(s, 0);
		case HashFunction.SimdJenkins:
			return simdJenkins(s);
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

unittest {
	benchmarkHashFunctions();
}

void benchmarkHashFunctions() {
	import falcor.hashfunctiontestdata;
	import std.datetime;
	import std.stdio;

	enum hfuns = [HashFunction.XXhash, HashFunction.Murmur,
			HashFunction.Siphash, HashFunction.Jenkins];
	TickDuration[hfuns.length] times;
	int[hfuns.length] collisions;
	for(int j = 0; j < 10; ++j) {
	foreach(hf; hfuns)
	{
		writeln(hf);
		int[] hashes = new int[cast(long)(manyStrings.length) - 1];
		hashes[] = 0;

		StopWatch sw;
		sw.start();
		for(int i = 0; i < 1000; ++i) {
			foreach(str; manyStrings) {
				hashes[hash(str, hf) % hashes.length] += 1;
			}
		}
		times[cast(int)hf] += sw.peek();

		foreach(it; hashes) {
			if(it > 1) {
				collisions[hf] += it;
			}
		}
	}
	}

	foreach(idx, TickDuration it; times) {
		writefln("%15s took %6dms with %10d collisions", hfuns[idx],
				it.msecs, collisions[idx]);
	}

}

string genSimdHashInsert(size_t cnt) {
	import std.format : format;
	string ret;
	for(int i = 0; i < cnt; ++i) {
		ret ~= format(
q{hash[%1$d] += str[i + %1$d];
hash[%1$d] += (hash[%1$d] << 10);
hash[%1$d] ^= (hash[%1$d] >> 6);
}, i);
	}
	return ret;
}

uint simdJenkins(string str) {
	import core.simd;

	const(size_t) strLen = str.length;
	const(size_t) div = 8UL;
	const(size_t) steps = strLen / div;
	const(size_t) remainingSteps = strLen % div;
	const(size_t) upTo = strLen - remainingSteps;

	ubyte[div] hash;

	for(size_t i = 0; i < upTo; i += div) {
		mixin(genSimdHashInsert(div));
		//pragma(msg, genSimdHashInsert(div));
	}

	for(size_t i = upTo; i < strLen; ++i) {
		mixin(genSimdHashInsert(1));
	}	

	for(size_t i = 1; i < div; ++i) {
		i += hash[i];
	}

    hash[0] += (hash[0] << 3);
    hash[0] ^= (hash[0] >> 11);
    hash[0] += (hash[0] << 15);

	return hash[0];
}
