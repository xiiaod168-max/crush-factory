"""Original deterministic paper/tape textures; no downloaded assets."""
from PIL import Image, ImageDraw, ImageFont
import random
from pathlib import Path
root = Path(__file__).resolve().parents[1]
rng = random.Random(421)
size = 768
im = Image.new('RGB', (size, size))
pixels = im.load()
for y in range(size):
    for x in range(size):
        n = rng.randrange(-10, 11) + (2 if x % 4 == 0 else 0)
        pixels[x,y] = (min(255,170+n), min(255,126+n), min(255,77+n))
draw = ImageDraw.Draw(im)
for _ in range(7000):
    x,y = rng.randrange(size),rng.randrange(size)
    draw.line((x,y,x+rng.randrange(1,5),y), fill=(156,114,68))
font_path = 'C:/Windows/Fonts/arialbd.ttf'
big = ImageFont.truetype(font_path, 42)
small = ImageFont.truetype(font_path, 21)
wall = im.copy()
d = ImageDraw.Draw(wall)
d.rectangle((338,0,428,768), fill=(153,109,57))
for x in (339,342,425,428): d.line((x,0,x,768), fill=(181,136,77), width=2)
d.rounded_rectangle((55,370,290,620),radius=2,outline=(65,53,39),width=4)
d.text((75,395),'RECOVER',font=big,fill=(57,48,34))
d.text((76,451),'CORRUGATED',font=small,fill=(61,49,35))
d.text((76,480),'PAPER / 04',font=small,fill=(61,49,35))
for x in (101,163):
    d.line((x,581,x,534), fill=(60,48,34), width=9)
    d.polygon([(x-15,549),(x,527),(x+15,549)],fill=(60,48,34))
d.text((76,660),'CF / B-001     0.8 KG',font=small,fill=(65,51,36))
wall.save(root/'assets/paper.png')
top = im.copy()
d = ImageDraw.Draw(top)
d.rectangle((0,329,768,439), fill=(153,109,57))
d.line((0,384,768,384),fill=(66,50,31),width=4)
d.line((384,0,384,329),fill=(78,58,34),width=3)
d.line((384,439,384,768),fill=(78,58,34),width=3)
top.save(root/'assets/paper-top.png')
