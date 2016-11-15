module falcor.spookyhash;

import core.stdc.string;

// converted from https://github.com/andikleen/spooky-c 
enum ALLOW_UNALIGNED_READS = true;

immutable SC_NUMVARS = 12;
immutable SC_BLOCKSIZE = (8 * SC_NUMVARS);
immutable SC_BUFSIZE = (2 * SC_BLOCKSIZE);
immutable SC_CONST = 0xdeadbeefdeadbeefL;

struct spooky_state {
	ulong[2 * SC_NUMVARS] m_data;
	ulong[SC_NUMVARS] m_state;
	size_t m_length;
	ubyte m_remainder;
}

ulong rot64(ulong x, int k)
{
	return (x << k) | (x >> (64 - k));
}

//
// This is used if the input is 96 bytes long or longer.
//
// The internal state is fully overwritten every 96 bytes.
// Every input bit appears to cause at least 128 bits of entropy
// before 96 other bytes are combined, when run forward or backward
//   For every input bit,
//   Two inputs differing in just that input bit
//   Where "differ" means xor or subtraction
//   And the base value is random
//   When run forward or backwards one Mix
// I tried 3 pairs of each; they all differed by at least 212 bits.
//
void mix
(
	const ulong *data,
	ulong *s0, ulong *s1, ulong *s2,  ulong *s3,
	ulong *s4, ulong *s5, ulong *s6,  ulong *s7,
	ulong *s8, ulong *s9, ulong *s10, ulong *s11
)
{
	*s0 += data[0];		*s2 ^= *s10;	*s11 ^= *s0;	*s0 = rot64(*s0, 11);	*s11 += *s1;
	*s1 += data[1];		*s3 ^= *s11;	*s0 ^= *s1;		*s1 = rot64(*s1, 32);	*s0 += *s2;
	*s2 += data[2];		*s4 ^= *s0;		*s1 ^= *s2;		*s2 = rot64(*s2, 43);	*s1 += *s3;
	*s3 += data[3];		*s5 ^= *s1;		*s2 ^= *s3;		*s3 = rot64(*s3, 31);	*s2 += *s4;
	*s4 += data[4];		*s6 ^= *s2;		*s3 ^= *s4;		*s4 = rot64(*s4, 17);	*s3 += *s5;
	*s5 += data[5];		*s7 ^= *s3;		*s4 ^= *s5;		*s5 = rot64(*s5, 28);	*s4 += *s6;
	*s6 += data[6];		*s8 ^= *s4;		*s5 ^= *s6;		*s6 = rot64(*s6, 39);	*s5 += *s7;
	*s7 += data[7];		*s9 ^= *s5;		*s6 ^= *s7;		*s7 = rot64(*s7, 57);	*s6 += *s8;
	*s8 += data[8];		*s10 ^= *s6;	*s7 ^= *s8;		*s8 = rot64(*s8, 55);	*s7 += *s9;
	*s9 += data[9];		*s11 ^= *s7;	*s8 ^= *s9;		*s9 = rot64(*s9, 54);	*s8 += *s10;
	*s10 += data[10];	*s0 ^= *s8;		*s9 ^= *s10;	*s10 = rot64(*s10, 22);	*s9 += *s11;
	*s11 += data[11];	*s1 ^= *s9;		*s10 ^= *s11;	*s11 = rot64(*s11, 46);	*s10 += *s0;
}

//
// Mix all 12 inputs together so that h0, h1 are a hash of them all.
//
// For two inputs differing in just the input bits
// Where "differ" means xor or subtraction
// And the base value is random, or a counting value starting at that bit
// The final result will have each bit of h0, h1 flip
// For every input bit,
// with probability 50 +- .3%
// For every pair of input bits,
// with probability 50 +- 3%
//
// This does not rely on the last Mix() call having already mixed some.
// Two iterations was almost good enough for a 64-bit result, but a
// 128-bit result is reported, so End() does three iterations.
//
void endPartial
(
	ulong *h0, ulong *h1, ulong *h2,  ulong *h3,
	ulong *h4, ulong *h5, ulong *h6,  ulong *h7,
	ulong *h8, ulong *h9, ulong *h10, ulong *h11
)
{
	*h11+= *h1;		*h2 ^= *h11;	*h1 = rot64(*h1, 44);
	*h0 += *h2;		*h3 ^= *h0;		*h2 = rot64(*h2, 15);
	*h1 += *h3;		*h4 ^= *h1;		*h3 = rot64(*h3, 34);
	*h2 += *h4;		*h5 ^= *h2;		*h4 = rot64(*h4, 21);
	*h3 += *h5;		*h6 ^= *h3;		*h5 = rot64(*h5, 38);
	*h4 += *h6;		*h7 ^= *h4;		*h6 = rot64(*h6, 33);
	*h5 += *h7;		*h8 ^= *h5;		*h7 = rot64(*h7, 10);
	*h6 += *h8;		*h9 ^= *h6;		*h8 = rot64(*h8, 13);
	*h7 += *h9;		*h10^= *h7;		*h9 = rot64(*h9, 38);
	*h8 += *h10;	*h11^= *h8;		*h10= rot64(*h10, 53);
	*h9 += *h11;	*h0 ^= *h9;		*h11= rot64(*h11, 42);
	*h10+= *h0;		*h1 ^= *h10;	*h0 = rot64(*h0, 54);
}

void end
(
	ulong *h0,	ulong *h1,	ulong *h2,	ulong *h3,
	ulong *h4,	ulong *h5,	ulong *h6,	ulong *h7,
	ulong *h8,	ulong *h9,	ulong *h10,	ulong *h11
)
{
	endPartial(h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11);
	endPartial(h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11);
	endPartial(h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11);
}

//
// The goal is for each bit of the input to expand into 128 bits of
//   apparent entropy before it is fully overwritten.
// n trials both set and cleared at least m bits of h0 h1 h2 h3
//   n: 2   m: 29
//   n: 3   m: 46
//   n: 4   m: 57
//   n: 5   m: 107
//   n: 6   m: 146
//   n: 7   m: 152
// when run forwards or backwards
// for all 1-bit and 2-bit diffs
// with diffs defined by either xor or subtraction
// with a base of all zeros plus a counter, or plus another bit, or random
//
void short_mix
(
	ulong *h0,
	ulong *h1,
	ulong *h2,
	ulong *h3
)
{
	*h2 = rot64(*h2, 50);	*h2 += *h3;  *h0 ^= *h2;
	*h3 = rot64(*h3, 52);	*h3 += *h0;  *h1 ^= *h3;
	*h0 = rot64(*h0, 30);	*h0 += *h1;  *h2 ^= *h0;
	*h1 = rot64(*h1, 41);	*h1 += *h2;  *h3 ^= *h1;
	*h2 = rot64(*h2, 54);	*h2 += *h3;  *h0 ^= *h2;
	*h3 = rot64(*h3, 48);	*h3 += *h0;  *h1 ^= *h3;
	*h0 = rot64(*h0, 38);	*h0 += *h1;  *h2 ^= *h0;
	*h1 = rot64(*h1, 37);	*h1 += *h2;  *h3 ^= *h1;
	*h2 = rot64(*h2, 62);	*h2 += *h3;  *h0 ^= *h2;
	*h3 = rot64(*h3, 34);	*h3 += *h0;  *h1 ^= *h3;
	*h0 = rot64(*h0, 5);	*h0 += *h1;  *h2 ^= *h0;
	*h1 = rot64(*h1, 36);	*h1 += *h2;  *h3 ^= *h1;
}

//
// Mix all 4 inputs together so that h0, h1 are a hash of them all.
//
// For two inputs differing in just the input bits
// Where "differ" means xor or subtraction
// And the base value is random, or a counting value starting at that bit
// The final result will have each bit of h0, h1 flip
// For every input bit,
// with probability 50 +- .3% (it is probably better than that)
// For every pair of input bits,
// with probability 50 +- .75% (the worst case is approximately that)
//
void short_end
(
	ulong *h0,
	ulong *h1,
	ulong *h2,
	ulong *h3
)
{
	*h3 ^= *h2;  *h2 = rot64(*h2, 15);  *h3 += *h2;
	*h0 ^= *h3;  *h3 = rot64(*h3, 52);  *h0 += *h3;
	*h1 ^= *h0;  *h0 = rot64(*h0, 26);  *h1 += *h0;
	*h2 ^= *h1;  *h1 = rot64(*h1, 51);  *h2 += *h1;
	*h3 ^= *h2;  *h2 = rot64(*h2, 28);  *h3 += *h2;
	*h0 ^= *h3;  *h3 = rot64(*h3, 9);   *h0 += *h3;
	*h1 ^= *h0;  *h0 = rot64(*h0, 47);  *h1 += *h0;
	*h2 ^= *h1;  *h1 = rot64(*h1, 54);  *h2 += *h1;
	*h3 ^= *h2;  *h2 = rot64(*h2, 32);  *h3 += *h2;
	*h0 ^= *h3;  *h3 = rot64(*h3, 25);  *h0 += *h3;
	*h1 ^= *h0;  *h0 = rot64(*h0, 63);  *h1 += *h0;
}

void spooky_shorthash
(
	const void *message,
	size_t length,
	ulong *hash1,
	ulong *hash2
)
{
	ulong[2 * SC_NUMVARS] buf;
	union U
	{
		const(ubyte) *p8;
		uint *p32;
		ulong *p64;
		size_t i;
	}

	U u;

	size_t remainder;
	//ulong a, b, c, d;
	u.p8 = cast(const ubyte *)message;

	if (!ALLOW_UNALIGNED_READS && (u.i & 0x7))
	{
		memcpy(buf.ptr, message, length);
		u.p64 = buf.ptr;
	}

	remainder = length % 32;
	ulong a = *hash1;
	ulong b = *hash2;
	ulong c = SC_CONST;
	ulong d = SC_CONST;

	if (length > 15)
	{
		const ulong *endp = u.p64 + (length/32)*4;

		// handle all complete sets of 32 bytes
		for (; u.p64 < endp; u.p64 += 4)
		{
			c += u.p64[0];
			d += u.p64[1];
			short_mix(&a, &b, &c, &d);
			a += u.p64[2];
			b += u.p64[3];
		}

		// Handle the case of 16+ remaining bytes.
		if (remainder >= 16)
		{
			c += u.p64[0];
			d += u.p64[1];
			short_mix(&a, &b, &c, &d);
			u.p64 += 2;
			remainder -= 16;
		}
	}

	// Handle the last 0..15 bytes, and its length
	d = (cast(ulong)length) << 56;
	switch (remainder)
	{
		case 15:
			d += (cast(ulong)u.p8[14]) << 48;
			goto case 14;
		case 14:
			d += (cast(ulong)u.p8[13]) << 40;
			goto case 13;
		case 13:
			d += (cast(ulong)u.p8[12]) << 32;
			goto case 12;
		case 12:
			d += u.p32[2];
			c += u.p64[0];
			break;
		case 11:
			d += (cast(ulong)u.p8[10]) << 16;
			goto case 11;
		case 10:
			d += (cast(ulong)u.p8[9]) << 8;
			goto case 9;
		case 9:
			d += cast(ulong)u.p8[8];
			goto case 8;
		case 8:
			c += u.p64[0];
			break;
		case 7:
			c += (cast(ulong)u.p8[6]) << 48;
			goto case 6;
		case 6:
			c += (cast(ulong)u.p8[5]) << 40;
			goto case 5;
		case 5:
			c += (cast(ulong)u.p8[4]) << 32;
			goto case 4;
		case 4:
			c += u.p32[0];
			break;
		case 3:
			c += (cast(ulong)u.p8[2]) << 16;
			goto case 3;
		case 2:
			c += (cast(ulong)u.p8[1]) << 8;
			goto case 2;
		case 1:
			c += cast(ulong)u.p8[0];
			break;
		case 0:
			c += SC_CONST;
			d += SC_CONST;
			break;
		default:
			assert(false);
	}
	short_end(&a, &b, &c, &d);
	*hash1 = a;
	*hash2 = b;
}

void spooky_init(spooky_state *state, ulong seed1, ulong seed2) {
	state.m_length = 0;
	state.m_remainder = 0;
	state.m_state[0] = seed1;
	state.m_state[1] = seed2;
}

void spooky_update(spooky_state *state,
		const void *message, size_t length)
{
	ulong h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11;
	size_t newLength = length + state.m_remainder;
	ubyte remainder;
	union U
	{
		const(ubyte) *p8;
		ulong *p64;
		size_t i;
	}
	U u;
	const(ulong) *endp;

	// Is this message fragment too short?  If it is, stuff it away.
	if (newLength < SC_BUFSIZE)
	{
		memcpy(&(cast(ubyte *)state.m_data)[state.m_remainder], message, length);
		state.m_length = length + state.m_length;
		state.m_remainder = cast(ubyte)newLength;
		return;
	}

	// init the variables
	if (state.m_length < SC_BUFSIZE)
	{
		h0 = h3 = h6 = h9  = state.m_state[0];
		h1 = h4 = h7 = h10 = state.m_state[1];
		h2 = h5 = h8 = h11 = SC_CONST;
	}
	else
	{
		h0 = state.m_state[0];
		h1 = state.m_state[1];
		h2 = state.m_state[2];
		h3 = state.m_state[3];
		h4 = state.m_state[4];
		h5 = state.m_state[5];
		h6 = state.m_state[6];
		h7 = state.m_state[7];
		h8 = state.m_state[8];
		h9 = state.m_state[9];
		h10 = state.m_state[10];
		h11 = state.m_state[11];
	}
	state.m_length = length + state.m_length;

	// if we've got anything stuffed away, use it now
	if (state.m_remainder)
	{
		ubyte prefix = cast(ubyte)(SC_BUFSIZE-state.m_remainder);
		memcpy(&((cast(ubyte *)state.m_data)[state.m_remainder]), message, prefix);
		u.p64 = state.m_data.ptr;
		mix(u.p64, &h0, &h1, &h2, &h3, &h4, &h5, &h6, &h7, &h8, &h9, &h10, &h11);
		mix(&u.p64[SC_NUMVARS], &h0, &h1, &h2, &h3, &h4, &h5, &h6, &h7, &h8, &h9, &h10, &h11);
		u.p8 = (cast(const ubyte *)message) + prefix;
		length -= prefix;
	}
	else
	{
		u.p8 = cast(const ubyte *)message;
	}

	// handle all whole blocks of SC_BLOCKSIZE bytes
	endp = u.p64 + (length/SC_BLOCKSIZE)*SC_NUMVARS;
	remainder = cast(ubyte)(length-(cast(const ubyte *)endp - u.p8));
	if (ALLOW_UNALIGNED_READS || (u.i & 0x7) == 0)
	{
		while (u.p64 < endp)
		{
			mix(u.p64, &h0, &h1, &h2, &h3, &h4, &h5, &h6, &h7, &h8, &h9, &h10, &h11);
			u.p64 += SC_NUMVARS;
		}
	}
	else
	{
		while (u.p64 < endp)
		{
			memcpy(state.m_data.ptr, u.p8, SC_BLOCKSIZE);
			mix(state.m_data.ptr, &h0, &h1, &h2, &h3, &h4, &h5, &h6, &h7, &h8, &h9, &h10, &h11);
			u.p64 += SC_NUMVARS;
		}
	}

	// stuff away the last few bytes
	state.m_remainder = remainder;
	memcpy(state.m_data.ptr, endp, remainder);

	// stuff away the variables
	state.m_state[0] = h0;
	state.m_state[1] = h1;
	state.m_state[2] = h2;
	state.m_state[3] = h3;
	state.m_state[4] = h4;
	state.m_state[5] = h5;
	state.m_state[6] = h6;
	state.m_state[7] = h7;
	state.m_state[8] = h8;
	state.m_state[9] = h9;
	state.m_state[10] = h10;
	state.m_state[11] = h11;
}

void spooky_final(spooky_state *state, ulong *hash1, ulong *hash2) {
	ulong h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11;
	const(ulong) *data = cast(const(ulong)*)state.m_data;
	ubyte remainder = state.m_remainder;

	// init the variables
	if (state.m_length < SC_BUFSIZE)
	{
		spooky_shorthash(state.m_data.ptr, state.m_length, hash1, hash2);
		return;
	}

	h0 = state.m_state[0];
	h1 = state.m_state[1];
	h2 = state.m_state[2];
	h3 = state.m_state[3];
	h4 = state.m_state[4];
	h5 = state.m_state[5];
	h6 = state.m_state[6];
	h7 = state.m_state[7];
	h8 = state.m_state[8];
	h9 = state.m_state[9];
	h10 = state.m_state[10];
	h11 = state.m_state[11];

	if (remainder >= SC_BLOCKSIZE)
	{
		// m_data can contain two blocks; handle any whole first block
		mix(data, &h0, &h1, &h2, &h3, &h4, &h5, &h6, &h7, &h8, &h9, &h10, &h11);
		data += SC_NUMVARS;
		remainder -= SC_BLOCKSIZE;
	}

	// mix in the last partial block, and the length mod SC_BLOCKSIZE
	memset(&(cast(ubyte *)data)[remainder], 0, (SC_BLOCKSIZE-remainder));

	(cast(ubyte *)data)[SC_BLOCKSIZE-1] = remainder;
	mix(data, &h0, &h1, &h2, &h3, &h4, &h5, &h6, &h7, &h8, &h9, &h10, &h11);

	// do some final mixing
	end(&h0, &h1, &h2, &h3, &h4, &h5, &h6, &h7, &h8, &h9, &h10, &h11);

	*hash1 = h0;
	*hash2 = h1;
}

void spooky_hash128(const void *message, size_t length, ulong *hash1,
		ulong *hash2)
{
	ulong h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11;
	ulong[SC_NUMVARS] buf;
	ulong *endp;
	union U
	{
		const(ubyte) *p8;
		ulong *p64;
		uint* i;
	}
	U u;
	size_t remainder;

	if (length < SC_BUFSIZE)
	{
		spooky_shorthash(message, length, hash1, hash2);
		return;
	}

	h0 = h3 = h6 = h9  = *hash1;
	h1 = h4 = h7 = h10 = *hash2;
	h2 = h5 = h8 = h11 = SC_CONST;

	u.p8 = cast(const(ubyte)*)message;
	endp = u.p64 + (length/SC_BLOCKSIZE)*SC_NUMVARS;

	// handle all whole blocks of SC_BLOCKSIZE bytes
	if (ALLOW_UNALIGNED_READS || (cast(uint)(u.i) & 0x7U) == 0)
	{
		while (u.p64 < endp)
		{
			mix(u.p64, &h0, &h1, &h2, &h3, &h4, &h5, &h6, &h7, &h8, &h9, &h10, &h11);
			u.p64 += SC_NUMVARS;
		}
	}
	else
	{
		while (u.p64 < endp)
		{
			memcpy(buf.ptr, u.p64, SC_BLOCKSIZE);
			mix(buf.ptr, &h0, &h1, &h2, &h3, &h4, &h5, &h6, &h7, &h8, &h9, &h10, &h11);
			u.p64 += SC_NUMVARS;
		}
	}

	// handle the last partial block of SC_BLOCKSIZE bytes
	remainder = (length - (cast(const ubyte *)endp-cast(const ubyte *)message));
	memcpy(buf.ptr, endp, remainder);
	memset((cast(ubyte*)(buf.ptr) + remainder), 0, SC_BLOCKSIZE - cast(ulong)remainder);
	(cast(ubyte *)buf)[SC_BLOCKSIZE-1] = cast(ubyte)remainder;
	mix(buf.ptr, &h0 , &h1, &h2, &h3, &h4, &h5, &h6, &h7, &h8, &h9, &h10, &h11);

	// do some final mixing
	end(&h0, &h1, &h2, &h3, &h4, &h5, &h6, &h7, &h8, &h9, &h10, &h11);
	*hash1 = h0;
	*hash2 = h1;
}

ulong spooky_hash64(const(ubyte) *message, size_t length, ulong seed) {
	ulong hash1 = seed;
	spooky_hash128(message, length, &hash1, &seed);
	return hash1;
}

/*uint spooky_hash64(const(string) message, ulong seed) {
	return spooky_hash64(
			cast(const(ubyte)*)cast(const(char)*)message.ptr, 
			message.length, 
			seed
		);
}*/

uint spooky_hash32(const(ubyte) *message, size_t length, ulong seed) {
	ulong hash1 = seed, hash2 = seed;
	spooky_hash128(message, length, &hash1, &hash2);
	return cast(uint)hash1;
}

uint spooky_hash32(const(string) message, ulong seed) {
	return spooky_hash32(cast(ubyte*)message.ptr, message.length, seed);
}

/*unittest {
	import std.stdio;
	import falcor.hashfunctiontestdata;
	foreach(string it; manyStrings) {
		writefln("%20s %10d", it, spooky_hash32(it, 0));
	}
}*/
