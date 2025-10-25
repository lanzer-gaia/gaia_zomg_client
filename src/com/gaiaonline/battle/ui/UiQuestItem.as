package com.gaiaonline.battle.ui
{
	import com.gaiaonline.battle.utils.BattleUtils;
	import com.gaiaonline.utils.VisManagerSingleParent;
	import com.gaiaonline.objectPool.LoaderFactory;
	
	import flash.display.DisplayObject;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.ColorTransform;
	import flash.net.URLRequest;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	
	public class UiQuestItem extends MovieClip
	{
		public static const EXTEND_CHANGED:String = "extend_changed" 
		
		public var txtQuestName:TextField;
		public var btnExtend:MovieClip;
		public var txtDesc:TextField;		
		public var mcBack:MovieClip;
		public var mcStepDetail:MovieClip;
		public var mcSpliter:MovieClip;
		
		private var _width:int = 200;		
		private var _highlight:Boolean = false;
		private var _extended:Boolean = false;		
		
		private var _completed:Boolean = false;
		private var _npcUrl:String;
		
		public var questId:String;	
		
		private var visManager:VisManagerSingleParent = null;
		private var visStepDetailManager:VisManagerSingleParent = null;		
		
		public function UiQuestItem()
		{
			super();
 			
 			this.visManager = new VisManagerSingleParent(this);
 			this.visStepDetailManager = new VisManagerSingleParent(this.mcStepDetail); 			
 									
			this.extend(this._extended);
			this.addEventListener(Event.ADDED_TO_STAGE, onAddedToStage, false, 0, true);
			this.btnExtend.addEventListener(MouseEvent.CLICK, onBtnExtendClick);
			
			this.txtDesc.autoSize = TextFieldAutoSize.LEFT;
		}
		
		private function onAddedToStage(evt:Event):void{
			this.resize();
			
			BattleUtils.disableMouseOnChildren(this);			
		}		
		
		
		private function onBtnExtendClick(evt:MouseEvent):void{
			this._extended = !this._extended;
			this.extend(this._extended);
			this.dispatchEvent(new Event(EXTEND_CHANGED));
		} 
		
		private function setDisplayObjectVisible(displayObject:DisplayObject, visible:Boolean):void {
			this.visManager.setVisible(displayObject, visible);
		}

		private function setStepDetailsDisplayObjectVisible(displayObject:DisplayObject, visible:Boolean):void {
			this.visStepDetailManager.setVisible(displayObject, visible);
		}
		
		private function resize():void{			
			this.txtQuestName.width = this._width - 15;
			this.txtQuestName.autoSize = TextFieldAutoSize.LEFT;
			var y:int = Math.ceil(this.txtQuestName.height) - 1;
						
			//--- Desc
			this.txtDesc.y = y;	
			this.setDisplayObjectVisible(this.txtDesc, this._extended);
			this.txtDesc.width = this._width - 5;
			this.txtDesc.autoSize = TextFieldAutoSize.LEFT;			
			if (this._extended){
				y += this.txtDesc.height;				
			}
			
			//--- Detail
			this.mcStepDetail.y = y;
			this.mcStepDetail.mcStepBg.width = this._width-3;
			this.mcStepDetail.txtStepLocation.x = this._width - this.mcStepDetail.txtStepLocation.width - 3;
			this.mcStepDetail.txtStepDesc.width = this._width - 5;
			this.mcStepDetail.txtStepDesc.autoSize = TextFieldAutoSize.LEFT;
						
			this.mcStepDetail.mcIcon.y = this.mcStepDetail.txtKill.y = Math.ceil(this.mcStepDetail.txtStepDesc.y + this.mcStepDetail.txtStepDesc.height);
			
			if (this.mcStepDetail.txtKill && this.mcStepDetail.txtKill.visible){				
				this.mcStepDetail.mcStepBg.height = this.mcStepDetail.txtStepDesc.height + this.mcStepDetail.txtKill.height;
			}else{
				this.mcStepDetail.mcStepBg.height = this.mcStepDetail.txtStepDesc.height;
			}
			
			this.mcBack.width = this.mcSpliter.width = this._width
			
			if (!this._completed){
				this.mcBack.height = this.mcStepDetail.y + this.mcStepDetail.height + 2; 
			}else{
				this.mcBack.height = y - 2;
			}	
		}
		
		
		public function updateInfo(obj:Object):void{
			
			if (obj.location == null){
				obj.location = "Unknown"
			}
			
			//-- Quest Name			
			this.txtQuestName.text = obj.questName;
			
			
			//--- Quest Desc
			this.txtDesc.addEventListener(Event.CHANGE, onTxtChange, false, 0, true);
			if (obj.npcImage != null){
				this._npcUrl = obj.npcImage;
			}			
			var desc:String
			if (this._npcUrl != null){
				desc = "<img src='" + this._npcUrl + "'/>"
			}
			desc = desc + "<font color='#FFFFFF'>Description:</font><BR>" + obj.questDesc;
			this.txtDesc.htmlText = desc;			
						
			if (obj.completed != null){
				this._completed = obj.completed;
			}else{
				this._completed = false;
			}			
			this.setDisplayObjectVisible(this.mcStepDetail, !this._completed);
			
			if (!this._completed){
				//---- Step Details				
				this.mcStepDetail.txtStepLocation.text = obj.location;
				this.mcStepDetail.txtStepDesc.text = obj.info || " ";				
				//---- Kill/Colection quest
				if(obj.goalProgress != null && obj.goalTotal != null && obj.questGoal != null){		
								
					var txt:String
					if (obj.stepType == 13){
						txt = obj.questGoal + " " + obj.goalProgress + " / " + obj.goalTotal;		
					} else{		
						txt = obj.goalProgress + " / " + obj.goalTotal;
					}
					this.mcStepDetail.txtKill.text = txt;
					if (obj.goalUrl != null){
						this.setStepDetailsDisplayObjectVisible(this.mcStepDetail.mcIcon, true);
						var l:Loader = LoaderFactory.getInstance().checkOut();
						l.contentLoaderInfo.addEventListener(Event.COMPLETE, onKillImgLoaded, false, 0, true);
						l.load(new URLRequest(obj.goalUrl));
					}else{
						this.setStepDetailsDisplayObjectVisible(this.mcStepDetail.mcIcon, false);						
						this.mcStepDetail.txtKill.x = 4;
					}					
					this.setStepDetailsDisplayObjectVisible(this.mcStepDetail.txtKill, true);											
				}else{
					this.setStepDetailsDisplayObjectVisible(this.mcStepDetail.mcIcon, false);											
					this.setStepDetailsDisplayObjectVisible(this.mcStepDetail.txtKill, false);																
				}			
			}			
			this.resize();
			
			
		}
		private function onKillImgLoaded(evt:Event):void{
			LoaderInfo(evt.target).loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, onKillImgLoaded);					
			while (MovieClip(this.mcStepDetail.mcIcon).numChildren > 0){
				MovieClip(this.mcStepDetail.mcIcon).removeChildAt(0);
			}
			MovieClip(this.mcStepDetail.mcIcon).addChild(LoaderInfo(evt.target).content);
			MovieClip(this.mcStepDetail.mcIcon).width = MovieClip(this.mcStepDetail.mcIcon).height = this.mcStepDetail.txtKill.height;
			this.mcStepDetail.txtKill.x = this.mcStepDetail.mcIcon.x + this.mcStepDetail.mcIcon.width + 2;
			
			LoaderFactory.getInstance().checkIn(LoaderInfo(evt.target).loader);
		}
		private function onTxtChange(evt:Event):void{
			this.txtDesc.removeEventListener(Event.CHANGE, onTxtChange);			
			this.txtDesc.addEventListener(Event.ENTER_FRAME, onTxtFrame, false, 0, true);			
		}
		private function onTxtFrame(evt:Event):void{
			this.txtDesc.removeEventListener(Event.ENTER_FRAME, onTxtFrame);
			this.resize();
		}
						
		private function extend(v:Boolean):void{
			this.setDisplayObjectVisible(this.txtDesc, v);
			if (v){
				this.btnExtend.gotoAndStop(1);				
			} else { 
				this.btnExtend.gotoAndStop(2); 
			};			
			this.resize();			
		}
		
		public function get extended():Boolean{
			return this._extended;
		}
		public function set extended(v:Boolean):void{
			this._extended = v;
			this.extend(this._extended);
		}

		public override function set width(v:Number):void{
			this._width = v;
			this.resize();
		}
		
		public function set completed(v:Boolean):void{
			this._completed = v;
			this.resize();
		}
		public function get completed():Boolean{
			return this._completed;
		}


		private static const s_highlightedColorTransform:ColorTransform = new ColorTransform(.7,.7,.7,1, 16, 25, 64, 0);
		private static const s_emptyColorTransform:ColorTransform = new ColorTransform();		
		public function set Highlight(v:Boolean):void{
			this._highlight = v;
			this.setDisplayObjectVisible(this.mcBack, this._highlight);
			if (this._highlight){
				MovieClip(this.mcStepDetail.mcStepBg).transform.colorTransform = s_highlightedColorTransform;
			}else{
				MovieClip(this.mcStepDetail.mcStepBg).transform.colorTransform = s_emptyColorTransform;
			}
		}
		public function get Highlight():Boolean{
			return this._highlight;
		}		
	}
}