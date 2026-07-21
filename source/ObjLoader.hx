package;

import openfl.utils.Assets;

typedef ModelFace =
{
	var v:Array<Int>;
	var uv:Array<Int>;
}

typedef Model =
{
	var vertices:Array<Float>;
	var uvs:Array<Float>;
	var faces:Array<ModelFace>;
}

class ObjLoader
{
	public static function load(path:String):Model
	{
		return parse(Assets.getText(path));
	}

	public static function parse(text:String):Model
	{
		var vertices:Array<Float> = [];
		var uvs:Array<Float> = [];
		var faces:Array<ModelFace> = [];

		for (line in text.split("\n"))
		{
			line = StringTools.trim(line);
			if (line == "" || StringTools.startsWith(line, "#"))
				continue;

			var parts = line.split(" ").filter(p -> p != "");
			switch (parts[0])
			{
				case "v":
					vertices.push(Std.parseFloat(parts[1]));
					vertices.push(Std.parseFloat(parts[2]));
					vertices.push(Std.parseFloat(parts[3]));
				case "vt":
					uvs.push(Std.parseFloat(parts[1]));
					uvs.push(1 - Std.parseFloat(parts[2]));
				case "f":
					var vIdx:Array<Int> = [];
					var uvIdx:Array<Int> = [];
					for (i in 1...parts.length)
					{
						var refs = parts[i].split("/");
						vIdx.push(Std.parseInt(refs[0]) - 1);
						uvIdx.push(refs.length > 1 && refs[1] != "" ? Std.parseInt(refs[1]) - 1 : -1);
					}
					for (i in 1...vIdx.length - 1)
						faces.push({v: [vIdx[0], vIdx[i], vIdx[i + 1]], uv: [uvIdx[0], uvIdx[i], uvIdx[i + 1]]});
				default:
			}
		}

		normalize(vertices);
		return {vertices: vertices, uvs: uvs, faces: faces};
	}

	static function normalize(vertices:Array<Float>):Void
	{
		if (vertices.length == 0)
			return;

		var minX = Math.POSITIVE_INFINITY, maxX = Math.NEGATIVE_INFINITY;
		var minY = Math.POSITIVE_INFINITY, maxY = Math.NEGATIVE_INFINITY;
		var minZ = Math.POSITIVE_INFINITY, maxZ = Math.NEGATIVE_INFINITY;
		var i = 0;
		while (i < vertices.length)
		{
			minX = Math.min(minX, vertices[i]);
			maxX = Math.max(maxX, vertices[i]);
			minY = Math.min(minY, vertices[i + 1]);
			maxY = Math.max(maxY, vertices[i + 1]);
			minZ = Math.min(minZ, vertices[i + 2]);
			maxZ = Math.max(maxZ, vertices[i + 2]);
			i += 3;
		}

		var cx = (minX + maxX) / 2;
		var cy = (minY + maxY) / 2;
		var cz = (minZ + maxZ) / 2;
		var size = Math.max(maxX - minX, Math.max(maxY - minY, maxZ - minZ));
		if (size <= 0)
			size = 1;
		var scale = 2 / size;

		i = 0;
		while (i < vertices.length)
		{
			vertices[i] = (vertices[i] - cx) * scale;
			vertices[i + 1] = (vertices[i + 1] - cy) * scale;
			vertices[i + 2] = (vertices[i + 2] - cz) * scale;
			i += 3;
		}
	}
}
