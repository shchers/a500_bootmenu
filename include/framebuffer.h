/* 
 * Acer bootloader boot menu application GUI
 * 
 * Copyright (C) 2012 Skrilax_CZ
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *
 */

#ifndef FRAMEBUFFER_H
#define FRAMEBUFFER_H

#define TEXT_LINES          39
#define TEXT_LINE_CHARS     80

/* RGBX color */
struct color
{
	uint8_t R, G, B, X;
};

/* Font color */
struct font_color
{
	struct color color;
	struct color outline;
};

/* color to int */
uint32_t clr2int(struct color clr);

/* int to color */
struct color int2clr (uint32_t u);

/* Initial text colors: 
 * Use colorcodes:
 * - 0x1B + R + G + B (range 01 - FF) to change color code of the text 
 * - 0x1C + R + G + B (range 01 - FF) to change color code of the background
 * - 0x1D transparent background
 */

/* Title color */
extern struct font_color title_color;

/* Text color */
extern struct font_color text_color;

/* Error text color */
extern struct font_color error_text_color;

/* Highlighting color */
extern struct color highlight_color;

/* Highlighted text color */
extern struct font_color highlight_text_color;

/*
 * Init framebuffer
 */
void fb_init();

/*
 * Set title
 */
void fb_set_title(const char* title_msg);

/*
 * Set status
 */
void fb_set_status(const char* status_msg);

/*
 * Draw text
 */
void fb_printf(const char* fmt, ...);

/*
 * Draw colored text
 */
void fb_color_printf(const char* fmt, const struct color* bkg, const struct font_color* clr, ...);

/*
 * Draw line (compatibility mode)
 */
void fb_compat_println(const char* fmt, ...);

/*
 * Draw error line (compatibility mode)
 */
void fb_compat_println_error(const char* fmt, ...);

/*
 * Text color code
 */
const char* fb_text_color_code(uint8_t r, uint8_t g, uint8_t b);
const char* fb_text_color_code2(const struct color* c);

/* 
 * Text outline color code
 */
const char* fb_text_outline_color_code(uint8_t r, uint8_t g, uint8_t b);
const char* fb_text_outline_color_code2(const struct color* c);

/*
 * Background color code
 * Specify 00, 00, 00 for transparent background
 */
const char* fb_background_color_code(uint8_t r, uint8_t g, uint8_t b);
const char* fb_background_color_code2(const struct color* c);

/*
 * Clear framebuffer
 */
void fb_clear();

/*
 * Refresh screen
 */
void fb_refresh();

#endif //!FRAMEBUFFER_H