{ config, lib, ... }:
{
  config.eiros.users.lcleveland.mangowc.settings.monitorrule = [
    "name:DP-4,rr:0,scale:1,x:0,y:0,width:1920,height:1200,refresh:60"
    "name:DP-3,rr:0,scale:1,x:0,y:1200,width:3840,height:1080,refresh:120"
  ];
}
