using UnityEngine;

public class Noise
{
    // RANDOM_TABLE.Length = 256
    static byte[] RANDOM_TABLE = new byte[] { 48, 112, 30, 254, 227, 236, 192, 188, 226, 9, 24, 32, 37, 195, 73, 132, 251, 135, 102, 218, 253, 173, 1, 80, 62, 135, 167, 49, 7, 236, 162, 235, 244, 28, 213, 196, 0, 78, 17, 185, 232, 6, 94, 64, 22, 21, 167, 4, 16, 127, 165, 215, 97, 165, 123, 73, 248, 40, 164, 250, 227, 49, 223, 179, 186, 75, 254, 65, 33, 3, 211, 61, 125, 93, 107, 11, 217, 82, 190, 93, 194, 0, 30, 172, 70, 170, 106, 76, 123, 208, 202, 4, 236, 89, 221, 48, 4, 94, 197, 234, 104, 137, 178, 156, 174, 41, 240, 125, 63, 55, 26, 81, 185, 254, 46, 167, 131, 251, 168, 150, 23, 245, 192, 178, 24, 55, 81, 11, 230, 231, 20, 253, 44, 250, 74, 201, 87, 117, 5, 185, 219, 255, 69, 225, 243, 168, 237, 156, 14, 5, 198, 43, 233, 105, 220, 247, 8, 224, 125, 134, 129, 160, 69, 66, 96, 240, 20, 229, 175, 74, 214, 125, 46, 217, 52, 223, 34, 125, 68, 70, 156, 6, 123, 178, 138, 153, 247, 24, 82, 186, 203, 57, 73, 100, 163, 78, 62, 54, 140, 146, 10, 150, 196, 124, 56, 78, 62, 29, 142, 151, 15, 233, 236, 34, 11, 249, 145, 35, 39, 72, 128, 14, 246, 126, 20, 235, 165, 204, 213, 140, 209, 240, 199, 53, 223, 30, 237, 116, 245, 55, 221, 166, 224, 12, 37, 109, 204, 179, 174, 213, 249, 120, 223, 245, 139, 11 };

    public static float Hash01(int x, int y)
    {
        var value = RANDOM_TABLE[x & 0b1111_1111];
        value = RANDOM_TABLE[(value ^ y) & 0b1111_1111];
        return (float)value / 255;
    }

    public static float Hash01(int x, int y, int z, int w)
    {
        var value = RANDOM_TABLE[x & 0b1111_1111];
        value = RANDOM_TABLE[(value ^ y) & 0b1111_1111];
        value = RANDOM_TABLE[(value ^ z) & 0b1111_1111];
        value = RANDOM_TABLE[(value ^ w) & 0b1111_1111];
        return (float)value / 255;
    }

    public static (float value, float dx, float dy) ValueNoise(float x, float y)
    {
        var ix = Mathf.FloorToInt(x);
        var iy = Mathf.FloorToInt(y);

        var fx = x - ix;
        var fy = y - iy;

        var ux = ((6 * fx - 15) * fx + 10) * fx * fx * fx;
        var uy = ((6 * fy - 15) * fy + 10) * fy * fy * fy;

        var dux = 30 * ((fx - 2) * fx + 1) * fx * fx;
        var duy = 30 * ((fy - 2) * fy + 1) * fy * fy;

        var v00 = Hash01(ix, iy);
        var v01 = Hash01(ix + 1, iy);
        var v11 = Hash01(ix + 1, iy + 1);
        var v10 = Hash01(ix, iy + 1);

        var k0 = v00;
        var k1 = -v00 + v01;
        var k2 = -v00 + v10;
        var k3 = v00 - v01 - v10 + v11;

        var f = k0 + k1 * ux + k2 * uy + k3 * ux * uy;
        var dx = (k1 + k3 * uy) * dux;
        var dy = (k2 + k3 * ux) * duy;
        return (f, dx, dy);
    }

    public static (float value, float dx, float dy) FBMNoise(float x, float y)
    {
        var amplitude = 1f;

        var value = 0f;
        var dx = 0f;
        var dy = 0f;

        for (var i = 0; i < 12; ++i)
        {
            var current = ValueNoise(x, y);

            dx += current.dx;
            dy += current.dy;
            value += amplitude * current.value;

            amplitude *= 0.5f;
            x *= 2;
            y *= 2;
        }

        return (value, dx, dy);
    }

    public static float ErosionFBMNoise(float x, float y)
    {
        var amplitude = 1f;

        var value = 0f;
        var dx = 0f;
        var dy = 0f;

        for (var i = 0; i < 12; ++i)
        {
            var current = ValueNoise(x, y);

            dx += current.dx;
            dy += current.dy;
            value += amplitude * current.value / (1 + dx * dx + dy * dy);

            amplitude *= 0.5f;
            x *= 2;
            y *= 2;
        }
        return value;
    }
}
