shader_type sky;

float noise(vec3 p) {
 vec3 i=floor(p); vec3 f=fract(p); f=f*f*(3.0-2.0*f);
 float n=dot(i,vec3(1.0,57.0,113.0));
 vec4 a=fract(sin(n+vec4(0.0,1.0,57.0,58.0))*43758.5453);
 vec4 b=fract(sin(n+vec4(113.0,114.0,170.0,171.0))*43758.5453);
 return mix(mix(mix(a.x,a.y,f.x),mix(a.z,a.w,f.x),f.y),mix(mix(b.x,b.y,f.x),mix(b.z,b.w,f.x),f.y),f.z);
}
void sky() {
 float elevation=max(0.0,EYEDIR.y);
 vec3 horizon=vec3(.29,.20,.18);
 vec3 zenith=vec3(.025,.048,.095);
 vec3 base=mix(horizon,zenith,pow(elevation,.42));
 vec3 p=EYEDIR*vec3(9.0,18.0,9.0)+vec3(TIME*.002,0.0,0.0);
 float f=noise(p)*.57+noise(p*2.03)*.28+noise(p*4.13)*.15;
 float cloud=smoothstep(.45,.67,f)*smoothstep(.015,.10,elevation)*(1.0-smoothstep(.58,.9,elevation));
 vec3 cloud_color=mix(vec3(.16,.12,.14),vec3(.065,.08,.115),elevation);
 COLOR=mix(base,cloud_color,cloud*.65);
 if(EYEDIR.y<0.0) COLOR=mix(horizon,vec3(.045,.07,.09),min(1.0,-EYEDIR.y*4.0));
 COLOR=pow(COLOR,vec3(2.2));
}
