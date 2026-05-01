#!/bin/sh
export SDL_MOUSE_TOUCH_EVENTS=1
export MOZ_USE_XINPUT2=1
export SDL_GAMECONTROLLERCONFIG="${SDL_GAMECONTROLLERCONFIG:+${SDL_GAMECONTROLLERCONFIG}
}0300b605202000000130000001000000,AYN Odin2 Gamepad,platform:Linux,x:b2,a:b1,b:b0,y:b3,back:b6,guide:b8,start:b7,dpleft:b13,dpdown:b12,dpright:b14,dpup:b11,leftshoulder:b4,lefttrigger:a2,rightshoulder:b5,righttrigger:a5,leftstick:b9,rightstick:b10,leftx:a0,lefty:a1,rightx:a3,righty:a4,"

