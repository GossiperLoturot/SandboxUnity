float3 hash (float3 p)
{
	p = float3(dot(p, float3(127.1, 311.7, 74.7)), dot(p, float3(269.5, 183.3, 246.1)), dot(p, float3(113.5, 271.9, 124.6)));
	return frac(sin(p) * 43758.5453123);
}

float3 dirHash (float3 p)
{
	return -1.0 + 2.0 * hash(p);
}

float gradNoise (float3 p)
{
	float3 i = floor(p);
	float3 f = frac(p);
	
	float3 u = ((6.0*f - 15.0)*f + 10.0)*f*f*f;
	
	float3 ga = dirHash(i + float3(0.0, 0.0, 0.0));
	float3 gb = dirHash(i + float3(1.0, 0.0, 0.0));
	float3 gc = dirHash(i + float3(0.0, 1.0, 0.0));
	float3 gd = dirHash(i + float3(1.0, 1.0, 0.0));
	float3 ge = dirHash(i + float3(0.0, 0.0, 1.0));
	float3 gf = dirHash(i + float3(1.0, 0.0, 1.0));
	float3 gg = dirHash(i + float3(0.0, 1.0, 1.0));
	float3 gh = dirHash(i + float3(1.0, 1.0, 1.0));
	
	float va = dot(ga, f - float3(0.0, 0.0, 0.0));
	float vb = dot(gb, f - float3(1.0, 0.0, 0.0));
	float vc = dot(gc, f - float3(0.0, 1.0, 0.0));
	float vd = dot(gd, f - float3(1.0, 1.0, 0.0));
	float ve = dot(ge, f - float3(0.0, 0.0, 1.0));
	float vf = dot(gf, f - float3(1.0, 0.0, 1.0));
	float vg = dot(gg, f - float3(0.0, 1.0, 1.0));
	float vh = dot(gh, f - float3(1.0, 1.0, 1.0));
	
	return va + 
		u.x*(vb - va) + 
		u.y*(vc - va) + 
		u.z*(ve - va) + 
		u.x*u.y*(va - vb - vc + vd) + 
		u.y*u.z*(va - vc - ve + vg) + 
		u.z*u.x*(va - vb - ve + vf) + 
		u.x*u.y*u.z*(-va + vb + vc - vd + ve - vf - vg + vh);
}

static const float kJitter = 0.7;
float cellularNoise (float3 p)
{
	float3 i = floor(p);
	float3 f = frac(p);
	float3 v000 = f - float3(0.5, 0.5, 0.5) + hash(i + float3(0, 0, 0));
	float3 v100 = f - float3(1.5, 0.5, 0.5) + hash(i + float3(1, 0, 0));
	float3 v010 = f - float3(0.5, 1.5, 0.5) + hash(i + float3(0, 1, 0));
	float3 v110 = f - float3(1.5, 1.5, 0.5) + hash(i + float3(1, 1, 0));
	float3 v001 = f - float3(0.5, 0.5, 1.5) + hash(i + float3(0, 0, 1));
	float3 v101 = f - float3(1.5, 0.5, 1.5) + hash(i + float3(1, 0, 1));
	float3 v011 = f - float3(0.5, 1.5, 1.5) + hash(i + float3(0, 1, 1));
	float3 v111 = f - float3(1.5, 1.5, 1.5) + hash(i + float3(1, 1, 1));
	return min(
		min(
			min(dot(v000, v000), dot(v100, v100)),
			min(dot(v010, v010), dot(v110, v110))
		), min(
			min(dot(v001, v001),dot(v101, v101)),
			min(dot(v011, v011), dot(v111, v111))
		)
	);
}