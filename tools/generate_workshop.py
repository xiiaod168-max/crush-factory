from pathlib import Path
from PIL import Image,ImageDraw,ImageFilter
import random,math
r=Path(__file__).resolve().parents[1]/'assets'; rng=random.Random(510)
for name,base in [('concrete',(69,73,72)),('wall',(48,58,61)),('paint',(145,109,32))]:
 im=Image.new('RGB',(512,512)); px=im.load()
 for y in range(512):
  for x in range(512):
   n=rng.randrange(-3,4)+int(2*math.sin(x*.07)+2*math.cos(y*.033))
   px[x,y]=tuple(max(0,min(255,c+n)) for c in base)
 d=ImageDraw.Draw(im)
 if name=='concrete':
  for k in range(180):
   x,y=rng.randrange(512),rng.randrange(512); d.line((x,y,x+rng.randrange(2,16),y+rng.randrange(-3,4)),fill=(49,53,52),width=1)
  d.line((0,0,511,0),fill=(28,31,30),width=3); d.line((0,0,0,511),fill=(28,31,30),width=3)
 elif name=='wall':
  for x in range(12,512,64):
   d.line((x,0,x,511),fill=(31,39,42),width=2)
   for y in [24,488]: d.ellipse((x+7,y,x+10,y+3),fill=(82,89,87))
 else:
  for i in range(170):
   x,y=rng.randrange(512),rng.randrange(512); n=rng.randrange(1,9)
   d.line((x,y,x+n,y+1),fill=(53,56,51),width=1)
 im.save(r/f'workshop-{name}.png')
oil=Image.new('RGBA',(256,256)); d=ImageDraw.Draw(oil)
for i in range(38):
 x,y=rng.randrange(45,175),rng.randrange(55,165); s=rng.randrange(8,42)
 d.ellipse((x,y,x+s,y+s*.45),fill=(13,17,18,rng.randrange(25,85)))
oil.filter(ImageFilter.GaussianBlur(3)).save(r/'workshop-oil.png')
print('Generated four original procedural workshop textures')

