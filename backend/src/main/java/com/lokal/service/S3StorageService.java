package com.lokal.service;

import jakarta.annotation.PostConstruct;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.CreateBucketRequest;
import software.amazon.awssdk.services.s3.model.HeadBucketRequest;
import software.amazon.awssdk.services.s3.model.NoSuchBucketException;
import software.amazon.awssdk.services.s3.model.ObjectCannedACL;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;
import software.amazon.awssdk.services.s3.model.S3Exception;

import java.io.IOException;
import java.util.UUID;

@Service
@ConditionalOnProperty(name = "lokal.storage.type", havingValue = "s3")
public class S3StorageService implements StorageService {

    private static final Logger log = LoggerFactory.getLogger(S3StorageService.class);

    private final S3Client s3Client;
    private final String bucket;
    private final String publicBaseUrl;
    private final boolean publicRead;
    private final boolean createBucket;

    public S3StorageService(
            S3Client s3Client,
            @Value("${lokal.storage.s3.bucket}") String bucket,
            @Value("${lokal.storage.s3.public-base-url}") String publicBaseUrl,
            @Value("${lokal.storage.s3.public-read:true}") boolean publicRead,
            @Value("${lokal.storage.s3.create-bucket:true}") boolean createBucket
    ) {
        this.s3Client = s3Client;
        this.bucket = bucket;
        if (publicBaseUrl == null || publicBaseUrl.isBlank()) {
            throw new IllegalStateException("lokal.storage.s3.public-base-url (S3_PUBLIC_BASE_URL) is required");
        }
        this.publicBaseUrl = LocalStorageService.trimTrailingSlash(publicBaseUrl);
        this.publicRead = publicRead;
        this.createBucket = createBucket;
    }

    @PostConstruct
    void ensureBucket() {
        try {
            s3Client.headBucket(HeadBucketRequest.builder().bucket(bucket).build());
            log.info("S3 bucket ready: {}", bucket);
        } catch (NoSuchBucketException e) {
            createBucketOrFail(e);
        } catch (S3Exception e) {
            // Some providers return 404 instead of NoSuchBucketException
            if (e.statusCode() == 404) {
                createBucketOrFail(e);
                return;
            }
            throw new IllegalStateException("Unable to access S3 bucket: " + bucket, e);
        }
    }

    private void createBucketOrFail(RuntimeException cause) {
        if (!createBucket) {
            throw new IllegalStateException("S3 bucket does not exist: " + bucket, cause);
        }
        log.info("Creating S3 bucket: {}", bucket);
        try {
            s3Client.createBucket(CreateBucketRequest.builder().bucket(bucket).build());
        } catch (S3Exception createError) {
            throw new IllegalStateException("Failed to create S3 bucket: " + bucket, createError);
        }
    }

    @Override
    public String store(MultipartFile file) {
        String contentType = LocalStorageService.validate(file);
        String key = "products/" + UUID.randomUUID() + LocalStorageService.extensionFor(contentType);

        final byte[] bytes;
        try {
            bytes = file.getBytes();
        } catch (IOException e) {
            throw new IllegalStateException("Failed to read upload", e);
        }

        PutObjectRequest.Builder put = PutObjectRequest.builder()
                .bucket(bucket)
                .key(key)
                .contentType(contentType)
                .contentLength((long) bytes.length);

        if (publicRead) {
            put.acl(ObjectCannedACL.PUBLIC_READ);
        }

        try {
            s3Client.putObject(put.build(), RequestBody.fromBytes(bytes));
        } catch (S3Exception e) {
            // R2 and some MinIO policies reject ACL — retry without it
            if (publicRead && e.statusCode() == 400) {
                log.warn("PutObject with ACL failed ({}), retrying without ACL", e.awsErrorDetails().errorMessage());
                s3Client.putObject(
                        PutObjectRequest.builder()
                                .bucket(bucket)
                                .key(key)
                                .contentType(contentType)
                                .contentLength((long) bytes.length)
                                .build(),
                        RequestBody.fromBytes(bytes)
                );
            } else {
                throw new IllegalStateException("Failed to store file in S3", e);
            }
        }

        return publicBaseUrl + "/" + key;
    }
}
