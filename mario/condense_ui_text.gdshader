// increase size of rainbow ui text to simulate condensed character spacing.
// will need adjustment if char size is ever changed from 16x20

shader_type canvas_item;

uniform float font_size = 42.0;

void vertex() {

	VERTEX.x += float(VERTEX_ID / 2) * (font_size * 0.2666666666666667);
	VERTEX.y -= float((2 - VERTEX_ID % 3) / 2 - 1) * (font_size / 3.0);
}