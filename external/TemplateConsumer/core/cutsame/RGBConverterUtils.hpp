/*
 * RGBConvertUtils.h - Arduino library for converting between RGB, HSV and HSL
 * 
 * Ported from the Javascript at http://mjijackson.com/2008/02/rgb-to-hsl-and-rgb-to-hsv-color-model-conversion-algorithms-in-javascript
 * The hard work was Michael's, all the bugs are mine.
 *
 * Robert Atkins, December 2010 (ratkins_at_fastmail_dot_fm).
 *
 * https://github.com/ratkins/RGBConverter
 *
 */
#ifndef TEMPLATECONSUMERAPP_RGBCONVERTER_HPP
#define TEMPLATECONSUMERAPP_RGBCONVERTER_HPP

#include <cstdint>

#include <algorithm>

namespace TemplateConsumer {

    namespace RGBConvertUtils {

        typedef unsigned char byte;

        static double threeway_max(double a, double b, double c) {
            return std::max(a, std::max(b, c));
        }

        static double threeway_min(double a, double b, double c) {
            return std::min(a, std::min(b, c));
        }

        static double hue2rgb(double p, double q, double t) {
            if (t < 0) t += 1;
            if (t > 1) t -= 1;
            if (t < 1 / 6.0) return p + (q - p) * 6 * t;
            if (t < 1 / 2.0) return q;
            if (t < 2 / 3.0) return p + (q - p) * (2 / 3.0 - t) * 6;
            return p;
        }

        /**
         * Converts an RGB color value to HSL. Conversion formula
         * adapted from http://en.wikipedia.org/wiki/HSL_color_space.
         * Assumes r, g, and b are contained in the set [0, 255] and
         * returns h, s, and l in the set [0, 1].
         *
         * @param   byte    r       The red color value
         * @param   byte    g       The green color value
         * @param   byte    b       The blue color value
         * @param   double  hsl[]   The HSL representation
         */
        static void rgbToHsl(byte r, byte g, byte b, double hsl[]) {
            double rd = (double) r / 255;
            double gd = (double) g / 255;
            double bd = (double) b / 255;
            double max = threeway_max(rd, gd, bd);
            double min = threeway_min(rd, gd, bd);
            double h, s, l = (max + min) / 2;

            if (max == min) {
                h = s = 0; // achromatic
            } else {
                double d = max - min;
                s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
                if (max == rd) {
                    h = (gd - bd) / d + (gd < bd ? 6 : 0);
                } else if (max == gd) {
                    h = (bd - rd) / d + 2;
                } else if (max == bd) {
                    h = (rd - gd) / d + 4;
                }
                h /= 6;
            }
            hsl[0] = h;
            hsl[1] = s;
            hsl[2] = l;
        }

        /**
         * Converts an HSL color value to RGB. Conversion formula
         * adapted from http://en.wikipedia.org/wiki/HSL_color_space.
         * Assumes h, s, and l are contained in the set [0, 1] and
         * returns r, g, and b in the set [0, 255].
         *
         * @param   double  h       The hue
         * @param   double  s       The saturation
         * @param   double  l       The lightness
         * @return  byte    rgb[]   The RGB representation
         */
        static void hslToRgb(double h, double s, double l, byte rgb[]) {
            double r, g, b;

            if (s == 0) {
                r = g = b = l; // achromatic
            } else {
                double q = l < 0.5 ? l * (1 + s) : l + s - l * s;
                double p = 2 * l - q;
                r = hue2rgb(p, q, h + 1 / 3.0);
                g = hue2rgb(p, q, h);
                b = hue2rgb(p, q, h - 1 / 3.0);
            }

            rgb[0] = r * 255;
            rgb[1] = g * 255;
            rgb[2] = b * 255;
        }

        /**
         * Converts an RGB color value to HSV. Conversion formula
         * adapted from http://en.wikipedia.org/wiki/HSV_color_space.
         * Assumes r, g, and b are contained in the set [0, 255] and
         * returns h, s, and v in the set [0, 1].
         *
         * @param   byte  r       The red color value
         * @param   byte  g       The green color value
         * @param   byte  b       The blue color value
         * @return  double hsv[]  The HSV representation
         */
        static void rgbToHsv(byte r, byte g, byte b, double hsv[]) {
            double rd = (double) r / 255;
            double gd = (double) g / 255;
            double bd = (double) b / 255;
            double max = threeway_max(rd, gd, bd), min = threeway_min(rd, gd, bd);
            double h, s, v = max;

            double d = max - min;
            s = max == 0 ? 0 : d / max;

            if (max == min) {
                h = 0; // achromatic
            } else {
                if (max == rd) {
                    h = (gd - bd) / d + (gd < bd ? 6 : 0);
                } else if (max == gd) {
                    h = (bd - rd) / d + 2;
                } else if (max == bd) {
                    h = (rd - gd) / d + 4;
                }
                h /= 6;
            }

            hsv[0] = h;
            hsv[1] = s;
            hsv[2] = v;
        }

        static void doubleRgbToHsv(double rd, double gd, double bd, double hsv[]) {
            double max = threeway_max(rd, gd, bd), min = threeway_min(rd, gd, bd);
            double h, s, v = max;

            double d = max - min;
            s = max == 0 ? 0 : d / max;

            if (max == min) {
                h = 0; // achromatic
            } else {
                if (max == rd) {
                    h = (gd - bd) / d + (gd < bd ? 6 : 0);
                } else if (max == gd) {
                    h = (bd - rd) / d + 2;
                } else if (max == bd) {
                    h = (rd - gd) / d + 4;
                }
                h /= 6;
            }

            hsv[0] = h;
            hsv[1] = s;
            hsv[2] = v;
        }

        static void rgbaToHsv(uint32_t rgba, double hsv[]) {
            doubleRgbToHsv(
                    (rgba & 0xFF000000) / 255.0,
                    (rgba & 0x00FF0000) / 255.0,
                    (rgba & 0x0000FF00) / 255.0,
                    hsv);
        }

        static void argbToHsv(uint32_t argb, double hsv[]) {
            doubleRgbToHsv(
                    (argb & 0x00FF0000) / 255.0,
                    (argb & 0x0000FF00) / 255.0,
                    (argb & 0x000000FF) / 255.0,
                    hsv);
        }

        /**
         * Converts an HSV color value to RGB. Conversion formula
         * adapted from http://en.wikipedia.org/wiki/HSV_color_space.
         * Assumes h, s, and v are contained in the set [0, 1] and
         * returns r, g, and b in the set [0, 255].
         *
         * @param   double  h       The hue
         * @param   double  s       The saturation
         * @param   double  v       The value
         * @return  byte    rgb[]   The RGB representation
         */
        static void hsvToRgb(double h, double s, double v, byte rgb[]) {
            double r, g, b;

            int i = int(h * 6);
            double f = h * 6 - i;
            double p = v * (1 - s);
            double q = v * (1 - f * s);
            double t = v * (1 - (1 - f) * s);

            switch (i % 6) {
                case 0:
                    r = v, g = t, b = p;
                    break;
                case 1:
                    r = q, g = v, b = p;
                    break;
                case 2:
                    r = p, g = v, b = t;
                    break;
                case 3:
                    r = p, g = q, b = v;
                    break;
                case 4:
                    r = t, g = p, b = v;
                    break;
                case 5:
                    r = v, g = p, b = q;
                    break;
            }

            rgb[0] = r * 255;
            rgb[1] = g * 255;
            rgb[2] = b * 255;
        }

        static void hsvToDoubleRgb(double h, double s, double v, double rgb[]) {
            double r, g, b;

            int i = int(h * 6);
            double f = h * 6 - i;
            double p = v * (1 - s);
            double q = v * (1 - f * s);
            double t = v * (1 - (1 - f) * s);

            switch (i % 6) {
                case 0:
                    r = v, g = t, b = p;
                    break;
                case 1:
                    r = q, g = v, b = p;
                    break;
                case 2:
                    r = p, g = v, b = t;
                    break;
                case 3:
                    r = p, g = q, b = v;
                    break;
                case 4:
                    r = t, g = p, b = v;
                    break;
                case 5:
                    r = v, g = p, b = q;
                    break;
            }

            rgb[0] = r;
            rgb[1] = g;
            rgb[2] = b;
        }
    }
}


#endif // TEMPLATECONSUMERAPP_RGBCONVERTER_HPP
