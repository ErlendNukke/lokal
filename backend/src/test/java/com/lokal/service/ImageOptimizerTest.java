package com.lokal.service;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockMultipartFile;

import javax.imageio.ImageIO;
import java.awt.Color;
import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

class ImageOptimizerTest {

    private ImageOptimizer optimizer;

    @BeforeEach
    void setUp() {
        optimizer = new ImageOptimizer(5 * 1024 * 1024, 600, 0.75f);
    }

    @Test
    void rejectsEmptyAndNonImage() {
        assertThrows(IllegalArgumentException.class,
                () -> optimizer.optimize(new MockMultipartFile("file", new byte[0])));
        assertThrows(IllegalArgumentException.class,
                () -> optimizer.optimize(
                        new MockMultipartFile("file", "a.txt", "text/plain", new byte[]{1})));
    }

    @Test
    void rejectsOversizeUpload() throws Exception {
        ImageOptimizer smallCap = new ImageOptimizer(50, 600, 0.75f);
        byte[] png = pngBytes(200, 200);
        assertTrue(png.length > 50);
        assertThrows(IllegalArgumentException.class,
                () -> smallCap.optimize(new MockMultipartFile("file", "a.png", "image/png", png)));
    }

    @Test
    void resizesLargeImageToJpegUnderMaxEdge() throws Exception {
        byte[] png = pngBytes(2400, 1800);
        var result = optimizer.optimize(new MockMultipartFile("file", "big.png", "image/png", png));

        assertEquals("image/jpeg", result.contentType());
        assertEquals(".jpg", result.extension());
        assertTrue(result.bytes().length > 0);

        BufferedImage out = ImageIO.read(new java.io.ByteArrayInputStream(result.bytes()));
        assertTrue(out.getWidth() <= 600);
        assertTrue(out.getHeight() <= 600);
        assertEquals(600, Math.max(out.getWidth(), out.getHeight()));
    }

    @Test
    void keepsSmallImageWithinBoundsAsJpeg() throws Exception {
        byte[] png = pngBytes(400, 300);
        var result = optimizer.optimize(new MockMultipartFile("file", "small.png", "image/png", png));
        BufferedImage out = ImageIO.read(new java.io.ByteArrayInputStream(result.bytes()));
        assertEquals(400, out.getWidth());
        assertEquals(300, out.getHeight());
    }

    private static byte[] pngBytes(int width, int height) throws Exception {
        BufferedImage image = new BufferedImage(width, height, BufferedImage.TYPE_INT_RGB);
        var g = image.createGraphics();
        g.setColor(Color.GREEN);
        g.fillRect(0, 0, width, height);
        g.dispose();
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        ImageIO.write(image, "png", out);
        return out.toByteArray();
    }
}
