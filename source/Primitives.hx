package;

import ObjLoader.Model;
import ObjLoader.ModelFace;

class Primitives
{
	public static function cube():Model
	{
		var v = [
			-1.0, -1, -1, 1, -1, -1, 1, 1, -1, -1, 1, -1,
			-1, -1, 1, 1, -1, 1, 1, 1, 1, -1, 1, 1
		];
		var uv = [0.0, 1, 1, 1, 1, 0, 0, 0];
		var quads = [
			[0, 3, 2, 1], [4, 5, 6, 7], [0, 1, 5, 4],
			[3, 7, 6, 2], [1, 2, 6, 5], [4, 7, 3, 0]
		];
		var faces:Array<ModelFace> = [];
		for (q in quads)
		{
			faces.push({v: [q[0], q[1], q[2]], uv: [0, 3, 2], color: -1});
			faces.push({v: [q[0], q[2], q[3]], uv: [0, 2, 1], color: -1});
		}
		return {vertices: v, uvs: uv, faces: faces};
	}

	public static function plane():Model
	{
		var v = [-1.0, 0, -1, 1, 0, -1, 1, 0, 1, -1, 0, 1];
		var uv = [0.0, 0, 1, 0, 1, 1, 0, 1];
		var faces:Array<ModelFace> = [
			{v: [0, 3, 2], uv: [0, 3, 2], color: -1},
			{v: [0, 2, 1], uv: [0, 2, 1], color: -1}
		];
		return {vertices: v, uvs: uv, faces: faces};
	}

	public static function sphere(latSegments:Int = 8, lonSegments:Int = 12):Model
	{
		var v:Array<Float> = [];
		var uv:Array<Float> = [];
		var faces:Array<ModelFace> = [];

		for (lat in 0...latSegments + 1)
		{
			var theta = lat * Math.PI / latSegments;
			var sinT = Math.sin(theta), cosT = Math.cos(theta);
			for (lon in 0...lonSegments + 1)
			{
				var phi = lon * 2 * Math.PI / lonSegments;
				v.push(Math.sin(phi) * sinT);
				v.push(cosT);
				v.push(Math.cos(phi) * sinT);
				uv.push(lon / lonSegments);
				uv.push(lat / latSegments);
			}
		}

		var stride = lonSegments + 1;
		for (lat in 0...latSegments)
		{
			for (lon in 0...lonSegments)
			{
				var a = lat * stride + lon;
				var b = a + stride;
				if (lat > 0)
					faces.push({v: [a, b, a + 1], uv: [a, b, a + 1], color: -1});
				if (lat < latSegments - 1)
					faces.push({v: [a + 1, b, b + 1], uv: [a + 1, b, b + 1], color: -1});
			}
		}
		return {vertices: v, uvs: uv, faces: faces};
	}

	public static function cylinder(segments:Int = 12):Model
	{
		var v:Array<Float> = [];
		var uv:Array<Float> = [];
		var faces:Array<ModelFace> = [];

		for (i in 0...segments + 1)
		{
			var phi = i * 2 * Math.PI / segments;
			var x = Math.sin(phi), z = Math.cos(phi);
			v.push(x);
			v.push(1);
			v.push(z);
			v.push(x);
			v.push(-1);
			v.push(z);
			uv.push(i / segments);
			uv.push(0);
			uv.push(i / segments);
			uv.push(1);
		}

		var topCenter = Std.int(v.length / 3);
		v.push(0);
		v.push(1);
		v.push(0);
		var bottomCenter = topCenter + 1;
		v.push(0);
		v.push(-1);
		v.push(0);
		var centerUV = Std.int(uv.length / 2);
		uv.push(0.5);
		uv.push(0.5);

		for (i in 0...segments)
		{
			var t0 = i * 2, b0 = i * 2 + 1, t1 = (i + 1) * 2, b1 = (i + 1) * 2 + 1;
			faces.push({v: [t0, b0, b1], uv: [t0, b0, b1], color: -1});
			faces.push({v: [t0, b1, t1], uv: [t0, b1, t1], color: -1});
			faces.push({v: [topCenter, t1, t0], uv: [centerUV, centerUV, centerUV], color: -1});
			faces.push({v: [bottomCenter, b0, b1], uv: [centerUV, centerUV, centerUV], color: -1});
		}
		return {vertices: v, uvs: uv, faces: faces};
	}
}
