package com.gaiaonline.battle.gateway
{
	import com.gaiaonline.flexModulesAPIs.actorInfo.ActorTypes;
	
	public class TransientActor
	{		
		public static var oldSchool:Boolean = false;
		public var id: String;
		public var hp: Number;
		public var hpMax: Number;
		public var actorName: String;
		public var pose: Number;
		public var rage: Number;
		public var speed: Number;
		public var actorType:ActorTypes;
		public var avatarURL: String;
		public var exhaustion: Number;
		public var x: Number;
		public var y: Number;
		public var actorRotation: Number;
		public var deltas: Array;
		public var statusLabels: Array;
		public var actions: Array;
		
		
		public function TransientActor( o: Object )
		{			
			if ( o.result != null )
			{				
				o = o.result;
			}
						
			
			if ( oldSchool )
			{
				handleOldSchoolData( o );
			}
			else
			{
				handleNewStyleResponse( o );
			}
		}

		private function handleNewStyleResponse( o:Object ): void
		{			
			
			try
			{				
				if ( o.id )
				{
					this.id = o.id;
					//log("  id = " +this.id);
				}
				else
				{
					trace("ERROR! no ID for this TransientActor");
				}
				
				
				if ( o.hp )
				{
					this.hp = parseInt( o.hp );
				}

				if ( o.hpm )
				{
					this.hpMax = parseInt( o.hpm );
				}
				
				if ( o.rotation )
				{
					this.actorRotation = o.rotation;
				}
				
				if ( o.nm )
				{
					this.actorName = o.nm;
				}
				
				if (o.pse)
				{
					this.pose = parseInt( o.pse );
				}

				if ( o.rag )
				{
					this.rage = parseInt( o.rag );
				}

				if ( o.exhaustion )
				{
					this.exhaustion = parseInt( o.exhaustion );
				}

				if ( o.spd )
				{
					this.speed = parseInt( o.spd );
				}

				if ( o.url )
				{
					this.avatarURL = o.url;
				}

				//if ( o.tp )
				//{
					this.actorType = ActorTypes.intToType(parseInt( o.tp ));
					//log("  this.actorType = " + this.actorType );
				//}

				if ( o.px )
				{
					this.x = parseInt( o.px );
				}

				if ( o.py )
				{
					this.y = parseInt( o.py );
				}
				
				if ( o.deltas )
				{
					try
					{
						this.deltas = new Array();
						for ( var p:String in o.deltas )
						{
							this.deltas.push( new TransientActorDelta( o.deltas[p] ) );
						}
					}
					catch (e:Error)
					{
						trace("Error trying to push a new TransientActorDelta");
					}
				}
				
				// TODO: test this..				
				if ( o.statusLabels )
				{					
					try
					{
						this.statusLabels = new Array();
						for ( var q:String in o.statusLabels )
						{
							this.statusLabels.push( new TransientActorStatus( o.statusLabels[q] ) );
						}
					}
					catch (e:Error)
					{
						trace("Error trying to push a new TransientActorStatus");
					}
				}
				
			
				if ( o.actionList )
				{
					try
					{
						this.actions = new Array();
						for ( var r:String in o.actionList )
						{
							this.actions.push( new TransientActorAction( o.actionList[r] ) );
						}
					}
					catch (e:Error)
					{
						trace("Error trying to push a new TransientActorAction");
					}
				}				
				
			}
			catch (e:Error)
			{
				trace("ERROR! creating this transient actor in the new style!");
			}
		}
		
		private function handleOldSchoolData( o:Object ): void
		{			
			try
			{
				if (o["id"])
				{
					this.id = o["id"];
					//log("  id = " +this.id);
				}
				else
				{
					trace("ERROR! no ID for this TransientActor");
				}
				
				if (o["hp"])
				{
					this.hp = parseInt(o["hp"]);
				}

				if (o["hpm"])
				{
					this.hpMax = parseInt(o["hpm"]);
				}
				
				if (o["nm"])
				{
					this.actorName = o["nm"];
				}
				
				if (o["pse"])
				{
					this.pose = parseInt(o["pse"]);
				}

				if (o["rage"])
				{
					this.rage = parseInt(o["rage"]);
				}

				if (o["spd"])
				{
					this.speed = parseInt(o["spd"]);
				}

				if (o["url"])
				{
					this.avatarURL = o["url"];
				}

				if (o["tp"])
				{
					this.actorType = ActorTypes.intToType(parseInt(o["tp"]));
				}

				if (o["px"])
				{
					this.x = parseInt(o["px"]);
				}

				if (o["py"])
				{
					this.y = parseInt(o["py"]);
				}
				
				if (o["eff"])
				{
					this.deltas = new Array();
					var aEff:Array = new Array();
					aEff = o["eff"].split("|");
					for (var i:int = 0; i < aEff.length; i++)
					{
						try
						{
							this.deltas.push( new TransientActorDelta( aEff[i] ) );
						}
						catch ( e: Error )
						{
							trace("Error trying to push a new TransientActorDelta");
						}
					}
				}
				
				// TODO: test this..
				if (o["status"])
				{					
					var aStatus:Array = new Array();
					aStatus = o["status"].split("|"); // is this really how it works?
					for ( var j:int = 0; j < aStatus.length; j++ )
					{
						try
						{
							this.statusLabels.push( new TransientActorStatus( aStatus[ j ] ) );
						}
						catch ( e: Error )
						{
							trace("Error trying to push a new TransientActorStatus");
						}
					}
				}
			}
			catch (e:Error)
			{
				trace("ERROR! creating this transient actor oldschool!");
			}
		}
		
	}
}