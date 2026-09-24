package com.lokal.support;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;

import java.util.UUID;

@SpringBootTest
@ActiveProfiles("test")
public abstract class IntegrationTestBase {

    protected static final ObjectMapper JSON = new ObjectMapper().findAndRegisterModules();

    @DynamicPropertySource
    static void isolateInMemoryDatabase(DynamicPropertyRegistry registry) {
        String dbName = "lokal-" + UUID.randomUUID();
        registry.add(
                "spring.datasource.url",
                () -> "jdbc:h2:mem:" + dbName
                        + ";MODE=PostgreSQL;DB_CLOSE_DELAY=-1;DATABASE_TO_LOWER=TRUE;DEFAULT_NULL_ORDERING=HIGH");
    }
}
