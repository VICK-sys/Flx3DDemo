package;

import ObjLoader.Model;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import openfl.Vector;
import openfl.display.BitmapData;
import openfl.display.Shape;
import openfl.display.TriangleCulling;
import openfl.geom.Rectangle;

class ModelSprite extends FlxSprite
{
	public var model(default, null):Model;
	public var texture:BitmapData;
	public var rotX:Float = 0;
	public var rotY:Float = 0;
	public var rotZ:Float = 0;
	public var spinX:Float = 0;
	public var spinY:Float = 0.9;
	public var spinZ:Float = 0;
	public var modelScale:Float = 1;
	public var baseColor:Int = 0x8888FF;
	public var ambient:Float = 0.35;
	public var vertexSnap:Bool = true;
	public var focal:Float = 240;
	public var camDistance:Float = 3.2;

	var modelPath:String;
	var needsReload:Bool = false;
	var shape:Shape;
	var clearRect:Rectangle;

	var camX:Array<Float> = [];
	var camY:Array<Float> = [];
	var camZ:Array<Float> = [];
	var scrX:Array<Float> = [];
	var scrY:Array<Float> = [];
	var visFace:Array<Int> = [];
	var visDepth:Array<Float> = [];
	var visNX:Array<Float> = [];
	var visNY:Array<Float> = [];
	var visNZ:Array<Float> = [];
	var visCount:Int = 0;
	var order:Array<Int> = [];
	var v2d:Vector<Float> = new Vector<Float>();
	var tris:Vector<Int> = new Vector<Int>();
	var uvt:Vector<Float> = new Vector<Float>();
	var depthComparator:(Int, Int) -> Int;

	var lastRotX:Float = Math.NaN;
	var lastRotY:Float = Math.NaN;
	var lastRotZ:Float = Math.NaN;
	var lastScale:Float = Math.NaN;
	var lastFocal:Float = Math.NaN;
	var lastCamDistance:Float = Math.NaN;
	var lastSnap:Bool = false;
	var lastTexture:BitmapData;
	var lastModel:Model;
	var lastBaseColor:Int = 0;
	var lastAmbient:Float = Math.NaN;

	static var lightX:Float;
	static var lightY:Float;
	static var lightZ:Float;

	static function __init__():Void
	{
		var len = Math.sqrt(0.4 * 0.4 + 0.7 * 0.7 + 0.6 * 0.6);
		lightX = 0.4 / len;
		lightY = 0.7 / len;
		lightZ = -0.6 / len;
	}

	public function new(x:Float, y:Float, viewWidth:Int, viewHeight:Int, ?modelPath:String, ?texture:BitmapData)
	{
		super(x, y);
		this.texture = texture;
		makeGraphic(viewWidth, viewHeight, 0x00000000, true);
		shape = new Shape();
		clearRect = new Rectangle(0, 0, viewWidth, viewHeight);
		depthComparator = compareDepth;
		ModelCache.onCleared.add(onCacheCleared);
		if (modelPath != null)
			loadModel(modelPath);
	}

	public function loadModel(path:String):ModelSprite
	{
		modelPath = path;
		model = ModelCache.get(path);
		if (model == null)
		{
			pixels.fillRect(clearRect, FlxColor.MAGENTA);
			dirty = true;
			return this;
		}

		var count = Std.int(model.vertices.length / 3);
		camX.resize(count);
		camY.resize(count);
		camZ.resize(count);
		scrX.resize(count);
		scrY.resize(count);
		visFace.resize(model.faces.length);
		visDepth.resize(model.faces.length);
		visNX.resize(model.faces.length);
		visNY.resize(model.faces.length);
		visNZ.resize(model.faces.length);
		lastRotX = Math.NaN;
		return this;
	}

	override public function update(elapsed:Float):Void
	{
		if (needsReload)
		{
			needsReload = false;
			loadModel(modelPath);
		}

		rotX += spinX * elapsed;
		rotY += spinY * elapsed;
		rotZ += spinZ * elapsed;
		super.update(elapsed);
	}

	override public function draw():Void
	{
		if (model != null && changed())
			render();
		super.draw();
	}

	override public function destroy():Void
	{
		ModelCache.onCleared.remove(onCacheCleared);
		super.destroy();
		model = null;
		texture = null;
		lastTexture = null;
		lastModel = null;
		shape = null;
		camX = camY = camZ = scrX = scrY = null;
		visFace = order = null;
		visDepth = visNX = visNY = visNZ = null;
		v2d = uvt = null;
		tris = null;
	}

	function onCacheCleared():Void
	{
		if (modelPath != null)
			needsReload = true;
	}

	function changed():Bool
	{
		if (rotX == lastRotX && rotY == lastRotY && rotZ == lastRotZ && modelScale == lastScale && focal == lastFocal && camDistance == lastCamDistance
			&& vertexSnap == lastSnap && texture == lastTexture && model == lastModel && baseColor == lastBaseColor && ambient == lastAmbient)
			return false;

		lastRotX = rotX;
		lastRotY = rotY;
		lastRotZ = rotZ;
		lastScale = modelScale;
		lastFocal = focal;
		lastCamDistance = camDistance;
		lastSnap = vertexSnap;
		lastTexture = texture;
		lastModel = model;
		lastBaseColor = baseColor;
		lastAmbient = ambient;
		return true;
	}

	function compareDepth(a:Int, b:Int):Int
	{
		var da = visDepth[a];
		var db = visDepth[b];
		return da < db ? 1 : (da > db ? -1 : 0);
	}

	function render():Void
	{
		var g = shape.graphics;
		g.clear();

		var cosX = Math.cos(rotX), sinX = Math.sin(rotX);
		var cosY = Math.cos(rotY), sinY = Math.sin(rotY);
		var cosZ = Math.cos(rotZ), sinZ = Math.sin(rotZ);
		var cx = frameWidth / 2;
		var cy = frameHeight / 2;

		var verts = model.vertices;
		var count = Std.int(verts.length / 3);
		for (i in 0...count)
		{
			var vx = verts[i * 3] * modelScale;
			var vy = verts[i * 3 + 1] * modelScale;
			var vz = verts[i * 3 + 2] * modelScale;

			var x1 = vx * cosY + vz * sinY;
			var z1 = -vx * sinY + vz * cosY;
			var y1 = vy * cosX - z1 * sinX;
			var z2 = vy * sinX + z1 * cosX;
			var x2 = x1 * cosZ - y1 * sinZ;
			var y2 = x1 * sinZ + y1 * cosZ;

			var zc = z2 + camDistance;
			camX[i] = x2;
			camY[i] = y2;
			camZ[i] = zc;

			var invZ = zc > 0.1 ? focal / zc : 0;
			var sx = cx + x2 * invZ;
			var sy = cy - y2 * invZ;
			if (vertexSnap)
			{
				sx = Std.int(sx);
				sy = Std.int(sy);
			}
			scrX[i] = sx;
			scrY[i] = sy;
		}

		visCount = 0;
		var faces = model.faces;
		for (fi in 0...faces.length)
		{
			var face = faces[fi];
			var a = face.v[0], b = face.v[1], c = face.v[2];
			if (camZ[a] <= 0.1 || camZ[b] <= 0.1 || camZ[c] <= 0.1)
				continue;

			var ux = camX[b] - camX[a], uy = camY[b] - camY[a], uz = camZ[b] - camZ[a];
			var wx = camX[c] - camX[a], wy = camY[c] - camY[a], wz = camZ[c] - camZ[a];
			var nx = uy * wz - uz * wy;
			var ny = uz * wx - ux * wz;
			var nz = ux * wy - uy * wx;

			if (nx * camX[a] + ny * camY[a] + nz * camZ[a] >= 0)
				continue;

			visFace[visCount] = fi;
			visDepth[visCount] = camZ[a] + camZ[b] + camZ[c];
			visNX[visCount] = nx;
			visNY[visCount] = ny;
			visNZ[visCount] = nz;
			visCount++;
		}

		order.resize(visCount);
		for (i in 0...visCount)
			order[i] = i;
		order.sort(depthComparator);

		if (texture != null)
		{
			v2d.length = 0;
			tris.length = 0;
			uvt.length = 0;
			var n = 0;
			for (i in 0...visCount)
			{
				var f = faces[visFace[order[i]]];
				for (k in 0...3)
				{
					v2d.push(scrX[f.v[k]]);
					v2d.push(scrY[f.v[k]]);
					var uvIdx = f.uv[k];
					uvt.push(uvIdx >= 0 ? model.uvs[uvIdx * 2] : 0);
					uvt.push(uvIdx >= 0 ? model.uvs[uvIdx * 2 + 1] : 0);
					tris.push(n++);
				}
			}
			g.beginBitmapFill(texture, null, false, false);
			g.drawTriangles(v2d, tris, uvt, TriangleCulling.NONE);
			g.endFill();
		}
		else
		{
			for (i in 0...visCount)
			{
				var slot = order[i];
				var nx = visNX[slot], ny = visNY[slot], nz = visNZ[slot];
				var len = Math.sqrt(nx * nx + ny * ny + nz * nz);
				var b = ambient;
				if (len > 0)
				{
					var d = (nx * lightX + ny * lightY + nz * lightZ) / len;
					if (d > 0)
						b += (1 - ambient) * d;
				}
				if (b > 1)
					b = 1;

				var r = Std.int(((baseColor >> 16) & 0xFF) * b);
				var gr = Std.int(((baseColor >> 8) & 0xFF) * b);
				var bl = Std.int((baseColor & 0xFF) * b);

				var f = faces[visFace[slot]];
				g.beginFill(0xFF000000 | (r << 16) | (gr << 8) | bl);
				g.moveTo(scrX[f.v[0]], scrY[f.v[0]]);
				g.lineTo(scrX[f.v[1]], scrY[f.v[1]]);
				g.lineTo(scrX[f.v[2]], scrY[f.v[2]]);
				g.endFill();
			}
		}

		pixels.fillRect(clearRect, 0x00000000);
		pixels.draw(shape);
		dirty = true;
	}
}
