package com.lokal.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import software.amazon.awssdk.auth.credentials.AwsBasicCredentials;
import software.amazon.awssdk.auth.credentials.StaticCredentialsProvider;
import software.amazon.awssdk.http.urlconnection.UrlConnectionHttpClient;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.S3Configuration;

import java.net.URI;

@Configuration
@ConditionalOnProperty(name = "lokal.storage.type", havingValue = "s3")
public class S3ClientConfig {

    @Bean(destroyMethod = "close")
    S3Client s3Client(
            @Value("${lokal.storage.s3.endpoint:}") String endpoint,
            @Value("${lokal.storage.s3.region:eu-central-1}") String region,
            @Value("${lokal.storage.s3.access-key}") String accessKey,
            @Value("${lokal.storage.s3.secret-key}") String secretKey,
            @Value("${lokal.storage.s3.path-style-access:}") String pathStyleAccess
    ) {
        boolean pathStyle = resolvePathStyle(endpoint, pathStyleAccess);

        var builder = S3Client.builder()
                .region(Region.of(region))
                .credentialsProvider(StaticCredentialsProvider.create(
                        AwsBasicCredentials.create(accessKey, secretKey)))
                .httpClient(UrlConnectionHttpClient.builder().build())
                .serviceConfiguration(S3Configuration.builder()
                        .pathStyleAccessEnabled(pathStyle)
                        .build());

        if (endpoint != null && !endpoint.isBlank()) {
            builder.endpointOverride(URI.create(endpoint));
        }

        return builder.build();
    }

    /**
     * MinIO typically needs path-style access. AWS S3 / Cloudflare R2 usually do not.
     * Explicit {@code lokal.storage.s3.path-style-access} wins when set.
     */
    static boolean resolvePathStyle(String endpoint, String pathStyleAccess) {
        if (pathStyleAccess != null && !pathStyleAccess.isBlank()) {
            return Boolean.parseBoolean(pathStyleAccess);
        }
        return endpoint != null && !endpoint.isBlank();
    }
}
