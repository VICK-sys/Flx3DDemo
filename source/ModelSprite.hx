package;

import ObjLoader.Model;
import flixel.FlxSprite;
import flixel.math.FlxPoint;
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
	public var pivotX:Float = 0;
	public var pivotY:Float = 0;
	public var pivotZ:Float = 0;
	public var baseColor:Int = 0x8888FF;
	public var ambient:Float = 0.35;
	public var vertexSnap:Bool = true;
	public var focal:Float = 240;
	public var camDistance:Float = 3.2;
	public var camYaw:Float = 0;
	public var camPitch:Float = 0;
	public var zoom:Float = 1;
	public var textureShading:Float = 1;
	public var fogEnabled:Bool = false;
	public var fogColor:Int = 0x000000;
	public var fogNear:Float = 2.4;
	public var fogFar:Float = 4.6;
	public var wireframe:Bool = false;
	public var wireColor:Int = 0x33FF66;
	public var wireThickness:Float = 1;

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
	var visBright:Array<Float> = [];
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
	var lastPivotX:Float = Math.NaN;
	var lastPivotY:Float = Math.NaN;
	var lastPivotZ:Float = Math.NaN;
	var lastFocal:Float = Math.NaN;
	var lastCamDistance:Float = Math.NaN;
	var lastCamYaw:Float = Math.NaN;
	var lastCamPitch:Float = Math.NaN;
	var lastZoom:Float = Math.NaN;
	var lastSnap:Bool = false;
	var lastTexture:BitmapData;
	var lastModel:Model;
	var lastBaseColor:Int = 0;
	var lastAmbient:Float = Math.NaN;
	var lastTextureShading:Float = Math.NaN;
	var lastFogEnabled:Bool = false;
	var lastFogColor:Int = 0;
	var lastFogNear:Float = Math.NaN;
	var lastFogFar:Float = Math.NaN;
	var lastWireframe:Bool = false;
	var lastWireColor:Int = 0;
	var lastWireThickness:Float = Math.NaN;

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
		var m = ModelCache.get(path);
		if (m == null)
		{
			modelPath = path;
			model = null;
			pixels.fillRect(clearRect, FlxColor.MAGENTA);
			dirty = true;
			return this;
		}
		setModel(m);
		modelPath = path;
		return this;
	}

	public function setModel(m:Model):ModelSprite
	{
		modelPath = null;
		model = m;
		var count = Std.int(m.vertices.length / 3);
		camX.resize(count);
		camY.resize(count);
		camZ.resize(count);
		scrX.resize(count);
		scrY.resize(count);
		visFace.resize(m.faces.length);
		visDepth.resize(m.faces.length);
		visBright.resize(m.faces.length);
		lastRotX = Math.NaN;
		return this;
	}

	public function worldToScreen(vx:Float, vy:Float, vz:Float, ?point:FlxPoint):FlxPoint
	{
		if (point == null)
			point = FlxPoint.get();

		vx = (vx - pivotX) * modelScale;
		vy = (vy - pivotY) * modelScale;
		vz = (vz - pivotZ) * modelScale;

		var cosX = Math.cos(rotX), sinX = Math.sin(rotX);
		var cosY = Math.cos(rotY), sinY = Math.sin(rotY);
		var cosZ = Math.cos(rotZ), sinZ = Math.sin(rotZ);
		var cosYw = Math.cos(camYaw), sinYw = Math.sin(camYaw);
		var cosP = Math.cos(camPitch), sinP = Math.sin(camPitch);

		var x1 = vx * cosY + vz * sinY;
		var z1 = -vx * sinY + vz * cosY;
		var y1 = vy * cosX - z1 * sinX;
		var z2 = vy * sinX + z1 * cosX;
		var x2 = x1 * cosZ - y1 * sinZ + pivotX * modelScale;
		var y2 = x1 * sinZ + y1 * cosZ + pivotY * modelScale;
		z2 += pivotZ * modelScale;

		var x3 = x2 * cosYw - z2 * sinYw;
		var z3 = x2 * sinYw + z2 * cosYw;
		var y3 = y2 * cosP - z3 * sinP;
		var z4 = y2 * sinP + z3 * cosP;

		var zc = z4 + camDistance;
		var invZ = zc > 0.1 ? focal * zoom / zc : 0;
		var sx = frameWidth / 2 + x3 * invZ;
		var sy = frameHeight / 2 - y3 * invZ;
		if (vertexSnap)
		{
			sx = Std.int(sx);
			sy = Std.int(sy);
		}
		point.set(sx, sy);
		return point;
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
		visDepth = visBright = null;
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
			&& pivotX == lastPivotX && pivotY == lastPivotY && pivotZ == lastPivotZ
			&& camYaw == lastCamYaw && camPitch == lastCamPitch && zoom == lastZoom && vertexSnap == lastSnap && texture == lastTexture
			&& model == lastModel && baseColor == lastBaseColor && ambient == lastAmbient && textureShading == lastTextureShading
			&& fogEnabled == lastFogEnabled && fogColor == lastFogColor && fogNear == lastFogNear && fogFar == lastFogFar
			&& wireframe == lastWireframe && wireColor == lastWireColor && wireThickness == lastWireThickness)
			return false;

		lastRotX = rotX;
		lastRotY = rotY;
		lastRotZ = rotZ;
		lastScale = modelScale;
		lastPivotX = pivotX;
		lastPivotY = pivotY;
		lastPivotZ = pivotZ;
		lastFocal = focal;
		lastCamDistance = camDistance;
		lastCamYaw = camYaw;
		lastCamPitch = camPitch;
		lastZoom = zoom;
		lastSnap = vertexSnap;
		lastTexture = texture;
		lastModel = model;
		lastBaseColor = baseColor;
		lastAmbient = ambient;
		lastTextureShading = textureShading;
		lastFogEnabled = fogEnabled;
		lastFogColor = fogColor;
		lastFogNear = fogNear;
		lastFogFar = fogFar;
		lastWireframe = wireframe;
		lastWireColor = wireColor;
		lastWireThickness = wireThickness;
		return true;
	}

	function compareDepth(a:Int, b:Int):Int
	{
		var da = visDepth[a];
		var db = visDepth[b];
		return da < db ? 1 : (da > db ? -1 : 0);
	}

	function fogFactor(slot:Int):Float
	{
		if (!fogEnabled)
			return 0;
		var z = visDepth[slot] / 3;
		var f = (z - fogNear) / (fogFar - fogNear);
		return f < 0 ? 0 : (f > 1 ? 1 : f);
	}

	function render():Void
	{
		var g = shape.graphics;
		g.clear();

		var cosX = Math.cos(rotX), sinX = Math.sin(rotX);
		var cosY = Math.cos(rotY), sinY = Math.sin(rotY);
		var cosZ = Math.cos(rotZ), sinZ = Math.sin(rotZ);
		var cosYw = Math.cos(camYaw), sinYw = Math.sin(camYaw);
		var cosP = Math.cos(camPitch), sinP = Math.sin(camPitch);
		var cx = frameWidth / 2;
		var cy = frameHeight / 2;
		var f2 = focal * zoom;

		var verts = model.vertices;
		var count = Std.int(verts.length / 3);
		for (i in 0...count)
		{
			var vx = (verts[i * 3] - pivotX) * modelScale;
			var vy = (verts[i * 3 + 1] - pivotY) * modelScale;
			var vz = (verts[i * 3 + 2] - pivotZ) * modelScale;

			var x1 = vx * cosY + vz * sinY;
			var z1 = -vx * sinY + vz * cosY;
			var y1 = vy * cosX - z1 * sinX;
			var z2 = vy * sinX + z1 * cosX;
			var x2 = x1 * cosZ - y1 * sinZ + pivotX * modelScale;
			var y2 = x1 * sinZ + y1 * cosZ + pivotY * modelScale;
			z2 += pivotZ * modelScale;

			var x3 = x2 * cosYw - z2 * sinYw;
			var z3 = x2 * sinYw + z2 * cosYw;
			var y3 = y2 * cosP - z3 * sinP;
			var z4 = y2 * sinP + z3 * cosP;

			var zc = z4 + camDistance;
			camX[i] = x3;
			camY[i] = y3;
			camZ[i] = zc;

			var invZ = zc > 0.1 ? f2 / zc : 0;
			var sx = cx + x3 * invZ;
			var sy = cy - y3 * invZ;
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

			var len = Math.sqrt(nx * nx + ny * ny + nz * nz);
			var bright = ambient;
			if (len > 0)
			{
				var d = (nx * lightX + ny * lightY + nz * lightZ) / len;
				if (d > 0)
					bright += (1 - ambient) * d;
			}
			if (bright > 1)
				bright = 1;

			visFace[visCount] = fi;
			visDepth[visCount] = camZ[a] + camZ[b] + camZ[c];
			visBright[visCount] = bright;
			visCount++;
		}

		order.resize(visCount);
		for (i in 0...visCount)
			order[i] = i;
		order.sort(depthComparator);

		if (wireframe)
		{
			g.lineStyle(wireThickness, 0xFF000000 | wireColor);
			for (i in 0...visCount)
			{
				var f = faces[visFace[order[i]]];
				g.moveTo(scrX[f.v[0]], scrY[f.v[0]]);
				g.lineTo(scrX[f.v[1]], scrY[f.v[1]]);
				g.lineTo(scrX[f.v[2]], scrY[f.v[2]]);
				g.lineTo(scrX[f.v[0]], scrY[f.v[0]]);
			}
			g.lineStyle();
		}
		else if (texture != null)
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

			var fogR = (fogColor >> 16) & 0xFF;
			var fogG = (fogColor >> 8) & 0xFF;
			var fogB = fogColor & 0xFF;
			for (i in 0...visCount)
			{
				var slot = order[i];
				var bright = 1 - (1 - visBright[slot]) * textureShading;
				var fog = fogFactor(slot);
				var alpha = 1 - bright * (1 - fog);
				if (alpha <= 0.004)
					continue;

				var r = Std.int(fogR * fog / alpha);
				var gr = Std.int(fogG * fog / alpha);
				var bl = Std.int(fogB * fog / alpha);
				if (r > 255) r = 255;
				if (gr > 255) gr = 255;
				if (bl > 255) bl = 255;

				var f = faces[visFace[slot]];
				g.beginFill((r << 16) | (gr << 8) | bl, alpha);
				g.moveTo(scrX[f.v[0]], scrY[f.v[0]]);
				g.lineTo(scrX[f.v[1]], scrY[f.v[1]]);
				g.lineTo(scrX[f.v[2]], scrY[f.v[2]]);
				g.endFill();
			}
		}
		else
		{
			var fogR = (fogColor >> 16) & 0xFF;
			var fogG = (fogColor >> 8) & 0xFF;
			var fogB = fogColor & 0xFF;
			for (i in 0...visCount)
			{
				var slot = order[i];
				var f = faces[visFace[slot]];
				var bright = visBright[slot];
				var fog = fogFactor(slot);
				var keep = bright * (1 - fog);

				var base = f.color >= 0 ? f.color : baseColor;
				var r = Std.int(((base >> 16) & 0xFF) * keep + fogR * fog);
				var gr = Std.int(((base >> 8) & 0xFF) * keep + fogG * fog);
				var bl = Std.int((base & 0xFF) * keep + fogB * fog);
				if (r > 255) r = 255;
				if (gr > 255) gr = 255;
				if (bl > 255) bl = 255;

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
