package aerys.minko.render
{
	import aerys.minko.Minko;
	import aerys.minko.ns.minko;
	import aerys.minko.render.effect.IPostProcessingEffect;
	import aerys.minko.render.effect.IRenderingEffect;
	import aerys.minko.render.effect.basic.BasicEffect;
	import aerys.minko.render.renderer.DefaultRenderer;
	import aerys.minko.render.renderer.IRenderer;
	import aerys.minko.render.renderer.RendererState;
	import aerys.minko.scene.data.RenderingData;
	import aerys.minko.scene.data.TransformData;
	import aerys.minko.scene.data.ViewportData;
	import aerys.minko.scene.node.IScene;
	import aerys.minko.scene.visitor.ISceneVisitor;
	import aerys.minko.scene.visitor.PostProcessingVisitor;
	import aerys.minko.scene.visitor.RenderingVisitor;
	import aerys.minko.scene.visitor.WorldDataVisitor;
	import aerys.minko.type.Factory;
	
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.display.Stage3D;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.display3D.Context3DRenderMode;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TouchEvent;
	import flash.geom.Point;
	import flash.utils.Dictionary;
	import flash.utils.getTimer;
	
	/**
	 * The viewport is the the display area used to render a 3D scene.
	 * It can be used to render any IScene3D object.
	 *
	 * @author Jean-Marc Le Roux
	 *
	 */
	public final class Viewport extends Sprite
	{
		use namespace minko;
		
		private static const ZERO2		: Point						= new Point();
		
		private const TRANSFORM_DATA	: TransformData				= new TransformData();
		private const RENDERING_DATA	: RenderingData				= new RenderingData();
		
		private var _width					: Number					= 0.;
		private var _height					: Number					= 0.;
		private var _stageX					: Number					= 0.;
		private var _stageY					: Number					= 0.;
		private var _autoResize				: Boolean					= false;
		private var _antiAliasing			: int						= 0;
		private var _invalidRectangle		: Boolean					= true;
		private var _upperLeft				: Point						= null;
		
		private var _visitors				: Vector.<ISceneVisitor>	= null;
		
		private var _renderingTime			: int						= 0;
		private var _drawingTime			: int						= 0;
		private var _sceneSize				: uint						= 0;
		private var _numTriangles			: uint						= 0;
		
		private var _stage3d				: Stage3D					= null;
		private var _rendererClass			: Class						= null;
		private var _renderer				: IRenderer					= null;
		private var _defaultEffect			: IRenderingEffect			= new BasicEffect();
		private var _backgroundColor		: int						= 0;
		
		private var _postProcessEffect		: IPostProcessingEffect		= null;
		private var _postProcessingVisitor	: ISceneVisitor				= new PostProcessingVisitor();
		
		private var _viewportData			: ViewportData				= null;
		private var _downScaleRT			: Boolean					= false;
		
		private var _logoIsHidden			: Boolean					= false;
		
		private var _mask					: Shape						= new Shape();
		private var _alwaysOnTop			: Boolean					= false;
		
		public function get downScaleRenderTarget() : Boolean
		{
			return _downScaleRT;
		}
		
		public function set downScaleRenderTarget(value : Boolean) : void
		{
			_downScaleRT = value;
		}
		
		public function get postProcessingEffect() : IPostProcessingEffect
		{
			return _postProcessEffect;
		}
		
		public function set postProcessingEffect(value : IPostProcessingEffect) : void
		{
			_postProcessEffect = value;
		}
		
		override public function set x(value : Number) : void
		{
			if (value != x)
			{
				super.x = value;
				_invalidRectangle = true;
			}
		}
		
		override public function set y(value : Number) : void
		{
			if (value != y)
			{
				super.y = value;
				_invalidRectangle = true;
			}
		}
		
		/**
		 * Indicates the width of the viewport.
		 * @return The width of the viewport.
		 *
		 */
		override public function get width()	: Number
		{
			return _width;
		}
		
		override public function set width(value : Number) : void
		{
			if (value != _width)
			{
				_width = value;
				_invalidRectangle = true;
			}
		}
		
		public function get frameId() : uint
		{
			return _renderer.frameId;
		}
		
		public function get sceneSize() : uint
		{
			return _sceneSize;
		}
		
		/**
		 * Indicates the height of the viewport.
		 * @return The height of the viewport.
		 *
		 */
		override public function get height() : Number
		{
			return _height;
		}
		
		override public function set height(value : Number) : void
		{
			if (value != _height)
			{
				_height = value;
				_invalidRectangle = true;
			}
		}
		
		/**
		 * The anti-aliasing value used to render the scene.
		 *
		 * @return
		 *
		 */
		public function get antiAliasing() : int
		{
			return _antiAliasing;
		}
		
		public function set antiAliasing(value : int) : void
		{
			if (value != _antiAliasing)
			{
				_antiAliasing = value;
				_invalidRectangle = true;
			}
		}
		
		public function get defaultEffect() : IRenderingEffect
		{
			return _defaultEffect;
		}
		
		public function set defaultEffect(value : IRenderingEffect) : void
		{
			_defaultEffect = value;
		}
		
		/**
		 * The amount of triangle rendered durung the last call to the
		 * "render" method. Sometimes, the number of triangles is higher
		 * than the total amount of triangles in the scene because some
		 * triangles are renderer multiple times (multipass).
		 *
		 * @return
		 *
		 */
		public function get numTriangles() : uint
		{
			return _numTriangles;
		}
		
		/**
		 * The time spent during the last call to the "render" method.
		 *
		 * This time includes:
		 * <ul>
		 * <li>updating the scene graph</li>
		 * <li>rendering the scene graph</li>
		 * <li>performing draw calls to the internal 3D APIs</li>
		 * </ul>
		 *
		 * @return
		 *
		 */
		public function get renderingTime() : uint
		{
			return _renderingTime;
		}
		
		public function get drawingTime() : int
		{
			return _drawingTime;
		}
		
		public function get renderMode() : String
		{
			return _stage3d && _stage3d.context3D ? _stage3d.context3D.driverInfo : null;
		}
		
		public function get backgroundColor() : int
		{
			return _backgroundColor;
		}
		
		public function set backgroundColor(value : int) : void
		{
			_backgroundColor = value;
		}
		
		public function get visitors() : Vector.<ISceneVisitor>
		{
			return _visitors;
		}
		
		public function get alwaysOnTop() : Boolean
		{
			return _alwaysOnTop;
		}
		
		public function set alwaysOnTop(value : Boolean) : void
		{
			_alwaysOnTop = value;
			
			updateMask();
			updateStageListeners();
		}
		
		/**
		 * Creates a new Viewport object.
		 *
		 * @param width The width of the viewport.
		 * @param height The height of the viewport.
		 */
		public function Viewport(antiAliasing	: int		= 0,
								 width			: uint		= 0,
								 height			: uint		= 0,
								 rendererType	: Class 	= null)
		{
			this.width = width;
			this.height = height;
			
			_autoResize		= width == 0 && height == 0;
			_antiAliasing	= antiAliasing;
			_rendererClass	= rendererType || DefaultRenderer;
			_viewportData	= new ViewportData(this);
			
			addEventListener(Event.ADDED, addedHandler);
			addEventListener(Event.REMOVED, removedHandler);
			addEventListener(Event.ADDED_TO_STAGE, addedToStageHandler);
			addEventListener(Event.REMOVED_FROM_STAGE, removedFromStage);
		}
		
		private function addedHandler(event : Event) : void
		{
			if (event.target != this)
				return ;

			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			
			if (_autoResize)
			{
				parent.addEventListener(Event.RESIZE, resizeHandler);
				resizeHandler();
			}
		}
		
		private function removedHandler(event : Event) : void
		{
			if (event.target == this)
				parent.removeEventListener(Event.RESIZE, resizeHandler);
		}
		
		private function addedToStageHandler(event : Event) : void
		{
			if (!_stage3d)
			{
				var stageId	: int	= 0;
				
				_stage3d = stage.stage3Ds[stageId];
				
				while (_stage3d.willTrigger(Event.CONTEXT3D_CREATE))
					_stage3d = stage.stage3Ds[int(++stageId)];
				
				_stage3d.addEventListener(Event.CONTEXT3D_CREATE, context3DCreatedHandler);
				_stage3d.requestContext3D(Context3DRenderMode.AUTO);
			}
			
			_stage3d.visible = true;
			
			if (!_logoIsHidden)
				showLogo();
			
			updateStageListeners();
			updateMask();
		}
		
		public function dispose() : void
		{
			if (_stage3d && _stage3d.context3D)
				_stage3d.context3D.dispose();
			_stage3d = null;
		}
		
		private function displayObjectAddedToStageHandler(event : Event) : void
		{
			var displayObject	: DisplayObject	= event.target as DisplayObject;
			
			if (displayObject.parent == stage)
				updateMask();
		}
		
		private function displayObjectRemovedFromStageHandler(event : Event) : void
		{
			var displayObject	: DisplayObject	= event.target as DisplayObject;
			
			if (_autoResize && displayObject.parent == stage)
				displayObject.mask = null;
		}
		
		private function removedFromStage(event : Event) : void
		{
			if (event.target != this)
				return ;
			
			_stage3d.visible = false;
			
			//			_stage3d.removeEventListener(Event.CONTEXT3D_CREATE, resetStage3D);
			//			_stage3d.context3D.dispose();
			//			_stage3d = null;
		}
		
		private function resizeHandler(event : Event = null) : void
		{
			if (parent == stage)
			{
				width = stage.stageWidth;
				height = stage.stageHeight;
			}
			else
			{
				var p : DisplayObject = parent;
				
				while (p && (p.width == 0 || p.height == 0))
					p = p.parent;
				
				if (p)
				{
					width = p.width;
					height = p.height;
				}
			}
			
			_invalidRectangle = true;
			
			if (!_logoIsHidden)
				showLogo();
		}
		
		private function context3DCreatedHandler(event : Event = null) : void
		{
			if (_stage3d && _stage3d.context3D && _width && _height)
			{
				_renderer = new _rendererClass(this, _stage3d.context3D);
				
				_visitors = Vector.<ISceneVisitor>([
					new WorldDataVisitor(),
					new RenderingVisitor()
				]);
				
				dispatchEvent(new Event(Event.INIT));
			}
		}
		
		private function updateSizeAndPosition() : void
		{
			if (_stage3d)
			{
				_upperLeft = localToGlobal(ZERO2);
				
				if (_width > 2048)
					_stageX = (_width - 2048) / 2.;
				else
					_stageX = _upperLeft.x;
				
				if (_height > 2048)
					_stageY = (_height - 2048) / 2.;
				else
					_stageY = _upperLeft.y;
				
				var width	: Number	= Math.min(2048, _width);
				var height	: Number	= Math.min(2048, _height);
				
				_stage3d.x = _stageX;
				_stage3d.y = _stageY;
				
				updateMask();
				
				if (_stage3d.context3D)
				{
					_stage3d.context3D.configureBackBuffer(
						width,
						height,
						_antiAliasing,
						true
					);
				}
			}
		}
		
		private function updateStageListeners() : void
		{
			if (!stage)
				return ;
			
			if (_alwaysOnTop)
			{
				stage.addEventListener(Event.RESIZE, stageResizeHandler);
				stage.addEventListener(Event.ADDED_TO_STAGE, displayObjectAddedToStageHandler);
				stage.addEventListener(Event.REMOVED_FROM_STAGE, displayObjectRemovedFromStageHandler);
				stage.addEventListener(MouseEvent.CLICK, stageEventHandler);
				stage.addEventListener(MouseEvent.DOUBLE_CLICK, stageEventHandler);
				stage.addEventListener(MouseEvent.MOUSE_DOWN, stageEventHandler);
				stage.addEventListener(MouseEvent.MOUSE_MOVE, stageEventHandler);
				stage.addEventListener(MouseEvent.MOUSE_OUT, stageEventHandler);
				stage.addEventListener(MouseEvent.MOUSE_OVER, stageEventHandler);
				stage.addEventListener(MouseEvent.MOUSE_WHEEL, stageEventHandler);
				stage.addEventListener(MouseEvent.ROLL_OUT, stageEventHandler);
				stage.addEventListener(MouseEvent.ROLL_OVER, stageEventHandler);
				stage.addEventListener(TouchEvent.TOUCH_BEGIN, stageEventHandler);
				stage.addEventListener(TouchEvent.TOUCH_END, stageEventHandler);
				stage.addEventListener(TouchEvent.TOUCH_MOVE, stageEventHandler);
				
			}
			else
			{
				stage.removeEventListener(Event.RESIZE, stageResizeHandler);
				stage.removeEventListener(Event.ADDED_TO_STAGE, displayObjectAddedToStageHandler);
				stage.removeEventListener(Event.REMOVED_FROM_STAGE, displayObjectRemovedFromStageHandler);
				stage.removeEventListener(MouseEvent.CLICK, stageEventHandler);
				stage.removeEventListener(MouseEvent.DOUBLE_CLICK, stageEventHandler);
				stage.removeEventListener(MouseEvent.MOUSE_DOWN, stageEventHandler);
				stage.removeEventListener(MouseEvent.MOUSE_MOVE, stageEventHandler);
				stage.removeEventListener(MouseEvent.MOUSE_OUT, stageEventHandler);
				stage.removeEventListener(MouseEvent.MOUSE_OVER, stageEventHandler);
				stage.removeEventListener(MouseEvent.MOUSE_WHEEL, stageEventHandler);
				stage.removeEventListener(MouseEvent.ROLL_OUT, stageEventHandler);
				stage.removeEventListener(MouseEvent.ROLL_OVER, stageEventHandler);
				stage.removeEventListener(TouchEvent.TOUCH_BEGIN, stageEventHandler);
				stage.removeEventListener(TouchEvent.TOUCH_END, stageEventHandler);
				stage.removeEventListener(TouchEvent.TOUCH_MOVE, stageEventHandler);
			}
		}
		
		private function stageResizeHandler(event : Event) : void
		{
			updateSizeAndPosition();
		}
		
		private function stageEventHandler(event : Object) : void
		{
			if (!_alwaysOnTop || event.target == this)
				return ;
			
			var stageX	: Number	= event.stageX;
			var stageY	: Number	= event.stageY;
			
			if (stageX > _stageX && stageX < _stageX + _width
				&& stageY > _stageY && stageY < _stageY + _height)
			{
				dispatchEvent(event.clone());
			}
		}
		
		private function updateMask() : void
		{
			if (!stage)
				return ;
			
			var numChildren : int = stage.numChildren;
			var i 			: int = 0;
			
			if (_alwaysOnTop)
			{
				var gfx			: Graphics	= _mask.graphics;
				var stageWidth	: int		= stage.stageWidth;
				var stageHeight	: int		= stage.stageHeight;
				
				gfx.clear();
				gfx.beginFill(0);
				gfx.moveTo(0, 0);
				gfx.lineTo(stageWidth, 0);
				gfx.lineTo(stageWidth, stageHeight);
				gfx.lineTo(0., stageHeight);
				gfx.lineTo(0, 0);
				gfx.moveTo(_stageX, _stageY);
				gfx.lineTo(_stageX, _stageY + height);
				gfx.lineTo(_stageX + width, _stageY + height);
				gfx.lineTo(_stageX + width, _stageY);
				gfx.lineTo(_stageX, _stageY);
				gfx.endFill();
				
				for (i = 0; i < numChildren; ++i)
					stage.getChildAt(i).mask = _mask;
			}
			else
			{
				for (i = 0; i < numChildren; ++i)
					stage.getChildAt(i).mask = null;
			}
		}
		
		/**
		 * Render the specified scene.
		 * @param scene
		 */
		public function render(scene : IScene, target : BitmapData = null) : void
		{
			if (!_logoIsHidden)
				showLogo();
			
			// update Stage3D position if necessary
			if (_stage3d)
			{
				var positionOnStage	: Point	= localToGlobal(ZERO2);
				
				if (_invalidRectangle
					|| _upperLeft.x != positionOnStage.x
					|| _upperLeft.y != positionOnStage.y)
				{
					updateSizeAndPosition();
					_invalidRectangle = false;
				}
			}
			
			// handle all visitor
			if (_visitors && _visitors.length != 0)
			{
				var time : Number = getTimer();
				
				// create the data sources the visitors are going to write and read from during render.
				var worldData		: Dictionary	= new Dictionary();
				
				// reset
				TRANSFORM_DATA.reset();
				RENDERING_DATA.reset();
				_renderer.reset();
				
				// push viewport related data into the world data
				worldData[ViewportData] = _viewportData;
				RENDERING_DATA.effects.push(defaultEffect);
				
				// execute all visitors
				for each (var visitor : ISceneVisitor in _visitors)
					visitor.processSceneGraph(scene, TRANSFORM_DATA, worldData, RENDERING_DATA, _renderer);
				
				RENDERING_DATA.effects.pop();
				_renderingTime	= getTimer() - time;
				_numTriangles = _renderer.numTriangles;
				_drawingTime = _renderer.drawingTime;
				
				// force clear if nothing was rendered
				if (_numTriangles == 0)
				{
					var clearState : RendererState	= RendererState.create();
					
					if (_postProcessEffect != null)
						clearState.renderTarget = _viewportData.renderTarget;
					else
						clearState.renderTarget = _viewportData.backBufferRenderTarget;
					
					_renderer.pushState(clearState);
					_renderer.drawToBackBuffer();
				}
				
				// execute post-processing
				if (_postProcessEffect != null)
				{
					RENDERING_DATA.effects.push(_postProcessEffect);
					_postProcessingVisitor.processSceneGraph(scene, TRANSFORM_DATA, worldData, RENDERING_DATA, _renderer);
					RENDERING_DATA.effects.pop();
				}
				
				if (target)
					_renderer.dumpBackbuffer(target);
				else
					_renderer.present();
				
				_sceneSize		= visitors[0].numNodes;
				_drawingTime	+= _renderer.drawingTime;
			}
			else
			{
				_renderingTime = 0;
				_numTriangles = 0;
				_drawingTime = 0;
			}
			
			Factory.sweep();
		}
		
		public function showLogo() : void
		{
			var logo : Sprite = Minko.logo;
			
			if (logo.parent != this)
				addChild(logo);
			
			logo.x = 5;
			logo.y = _height - logo.height - 5;
		}
		
		public function hideLogo() : void
		{
			_logoIsHidden = true;
			if (contains(Minko.logo))
				removeChild(Minko.logo);
		}
	}
}
