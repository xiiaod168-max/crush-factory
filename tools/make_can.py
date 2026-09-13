"""Original painted aluminum label; no external assets."""
from PIL import Image, ImageDraw, ImageFont
from pathlib import Path
import random
root=Path(__file__).resolve().parents[1]
im=Image.new('RGB',(1024,1024),'#126879')
d=ImageDraw.Draw(im)
random.seed(18)
for y in range(1024):
    shade=random.randrange(-5,6)
    d.line((0,y,1024,y),fill=(28+shade,130+shade,145+shade))
for y in [0,970]: d.rectangle((0,y,1024,y+54),fill='#bdc7cc')
for x in [90,590]:
    d.polygon([(x-90,910),(x+85,110),(x+150,110),(x-25,910)],fill='#e5bd62')
font=ImageFont.truetype('C:/Windows/Fonts/arialbd.ttf',76)
small=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',24)
for x in [210,710]:
    d.text((x,320),'CF',font=font,fill='#edf0e5',anchor='mm')
    d.text((x,402),'ALUMINUM',font=small,fill='#edf0e5',anchor='mm')
    d.text((x,446),'EMPTY / 330',font=small,fill='#bdd2cc',anchor='mm')
    for i in range(36):
        px=x-58+i*3
        d.rectangle((px,720,px+random.choice([1,2]),792),fill='#ced3c5')
    d.text((x,839),'RECYCLE',font=small,fill='#edf0e5',anchor='mm')
im.save(root/'assets/can-label.png')
lid=Image.new('RGB',(512,512),'#b8c0c4')
draw=ImageDraw.Draw(lid)
for inset,color,width in [(10,'#e1e6e8',6),(30,'#78868c',3),(43,'#d4dcdf',5),(57,'#89979d',2)]:
    draw.ellipse((inset,inset,512-inset,512-inset),outline=color,width=width)
draw.ellipse((194,105,318,237),fill='#65737a',outline='#e2e7e9',width=4)
draw.rounded_rectangle((210,211,310,361),radius=40,fill='#66757d')
draw.rounded_rectangle((202,204,302,354),radius=40,fill='#dce3e6',outline='#8b989f',width=4)
draw.ellipse((222,260,282,331),fill='#65737b',outline='#edf0f1',width=3)
draw.ellipse((240,218,264,242),fill='#a8b4bb',outline='#f1f3f4',width=3)
lid.save(root/'assets/can-lid.png')
