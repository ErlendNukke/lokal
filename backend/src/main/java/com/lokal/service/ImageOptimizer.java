package com.lokal.service;

import net.coobird.thumbnailator.Thumbnails;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import javax.imageio.IIOImage;
import javax.imageio.ImageIO;
import javax.imageio.ImageWriteParam;
import javax.imageio.ImageWriter;
import javax.imageio.stream.ImageOutputStream;
import java.awt.image.BufferedImage;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.util.Iterator;
import java.util.Locale;
import java.util.Set;

/**
 * Caps upload size and re-encodes product photos to a bounded JPEG for marketplace use.
 * Default: max 5&nbsp;MB in, longest edge 600px (thumbnail), JPEG quality 0.75 (~30–120&nbsp;KB out).
 */
@Service
public class ImageOptimizer {

    public static final String OUTPUT_CONTENT_TYPE = "image/jpeg";
    public static final String OUTPUT_EXTENSION = ".jpg";

    private static final Set<String> ALLOWED = Set.of(
            "image/jpeg", "image/jpg", "image/png", "image/webp", "image/gif"
    );

    private final long maxUploadBytes;
    private final int maxEdgePx;
    private final float jpegQuality;

    public ImageOptimizer(
            @Value("${lokal.storage.max-upload-bytes:5242880}") long maxUploadBytes,
            @Value("${lokal.storage.max-edge-px:600}") int maxEdgePx,
            @Value("${lokal.storage.jpeg-quality:0.75}") float jpegQuality
    ) {
        this.maxUploadBytes = maxUploadBytes;
        this.maxEdgePx = maxEdgePx;
        this.jpegQuality = Math.clamp(jpegQuality, 0.50f, 0.95f);
    }

    public OptimizedImage optimize(MultipartFile file) {
        if (file == null || file.isEmpty()) {
            throw new IllegalArgumentException("Empty file");
        }
        if (file.getSize() > maxUploadBytes) {
            throw new IllegalArgumentException(
                    "Image too large (max " + (maxUploadBytes / (1024 * 1024)) + " MB)");
        }
        String contentType = normalizeContentType(file.getContentType());
        if (!ALLOWED.contains(contentType)) {
            throw new IllegalArgumentException("Only JPEG, PNG, WEBP, GIF images are allowed");
        }

        final byte[] original;
        try {
            original = file.getBytes();
        } catch (IOException e) {
            throw new IllegalArgumentException("Failed to read upload", e);
        }
        if (original.length > maxUploadBytes) {
            throw new IllegalArgumentException(
                    "Image too large (max " + (maxUploadBytes / (1024 * 1024)) + " MB)");
        }

        final BufferedImage source;
        try {
            source = ImageIO.read(new ByteArrayInputStream(original));
        } catch (IOException e) {
            throw new IllegalArgumentException("Could not read image", e);
        }
        if (source == null) {
            throw new IllegalArgumentException("Could not decode image");
        }

        try {
            BufferedImage scaled = scaleIfNeeded(source);
            byte[] jpeg = encodeJpeg(scaled);
            return new OptimizedImage(jpeg, OUTPUT_CONTENT_TYPE, OUTPUT_EXTENSION);
        } catch (IOException e) {
            throw new IllegalArgumentException("Failed to optimize image", e);
        }
    }

    private BufferedImage scaleIfNeeded(BufferedImage source) throws IOException {
        int w = source.getWidth();
        int h = source.getHeight();
        if (w <= 0 || h <= 0) {
            throw new IllegalArgumentException("Invalid image dimensions");
        }
        if (w <= maxEdgePx && h <= maxEdgePx) {
            // Ensure RGB (drop alpha) for JPEG
            if (source.getType() == BufferedImage.TYPE_INT_RGB) {
                return source;
            }
            return Thumbnails.of(source).scale(1.0).asBufferedImage();
        }
        return Thumbnails.of(source)
                .size(maxEdgePx, maxEdgePx)
                .asBufferedImage();
    }

    private byte[] encodeJpeg(BufferedImage image) throws IOException {
        Iterator<ImageWriter> writers = ImageIO.getImageWritersByFormatName("jpg");
        if (!writers.hasNext()) {
            throw new IllegalStateException("No JPEG writer available");
        }
        ImageWriter writer = writers.next();
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        try (ImageOutputStream ios = ImageIO.createImageOutputStream(out)) {
            writer.setOutput(ios);
            ImageWriteParam param = writer.getDefaultWriteParam();
            if (param.canWriteCompressed()) {
                param.setCompressionMode(ImageWriteParam.MODE_EXPLICIT);
                param.setCompressionQuality(jpegQuality);
            }
            // Flatten onto white background if the image has alpha
            BufferedImage rgb = image;
            if (image.getColorModel().hasAlpha()) {
                rgb = new BufferedImage(image.getWidth(), image.getHeight(), BufferedImage.TYPE_INT_RGB);
                var g = rgb.createGraphics();
                g.setColor(java.awt.Color.WHITE);
                g.fillRect(0, 0, image.getWidth(), image.getHeight());
                g.drawImage(image, 0, 0, null);
                g.dispose();
            }
            writer.write(null, new IIOImage(rgb, null, null), param);
        } finally {
            writer.dispose();
        }
        return out.toByteArray();
    }

    static String normalizeContentType(String contentType) {
        if (contentType == null || contentType.isBlank()) {
            return "";
        }
        String ct = contentType.toLowerCase(Locale.ROOT).split(";")[0].trim();
        if ("image/jpg".equals(ct)) {
            return "image/jpeg";
        }
        return ct;
    }

    public record OptimizedImage(byte[] bytes, String contentType, String extension) {}
}
