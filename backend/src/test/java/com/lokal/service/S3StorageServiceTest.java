package com.lokal.service;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.DeleteObjectRequest;
import software.amazon.awssdk.services.s3.model.S3Exception;

import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoMoreInteractions;

@ExtendWith(MockitoExtension.class)
class S3StorageServiceTest {

    @Mock
    S3Client s3Client;

    @Test
    void deleteManagedUrls_deletesMatchingKeysOnly() {
        S3StorageService service = new S3StorageService(
                s3Client, "lokal-bucket", "https://pub.example.r2.dev", true, false);

        service.deleteManagedUrls(List.of(
                "https://pub.example.r2.dev/products/one.jpg",
                "https://images.unsplash.com/other.jpg",
                "https://pub.example.r2.dev/products/two.png"));

        ArgumentCaptor<DeleteObjectRequest> captor = ArgumentCaptor.forClass(DeleteObjectRequest.class);
        verify(s3Client, times(2)).deleteObject(captor.capture());
        assertEquals("lokal-bucket", captor.getAllValues().get(0).bucket());
        assertEquals("products/one.jpg", captor.getAllValues().get(0).key());
        assertEquals("products/two.png", captor.getAllValues().get(1).key());
        verifyNoMoreInteractions(s3Client);
    }

    @Test
    void deleteManagedUrls_logsAndContinuesOnS3Error() {
        S3StorageService service = new S3StorageService(
                s3Client, "lokal-bucket", "https://pub.example.r2.dev", true, false);
        doThrow(S3Exception.builder().message("network blip").build())
                .when(s3Client).deleteObject(any(DeleteObjectRequest.class));

        service.deleteManagedUrls(List.of("https://pub.example.r2.dev/products/x.jpg"));

        verify(s3Client).deleteObject(any(DeleteObjectRequest.class));
    }
}
