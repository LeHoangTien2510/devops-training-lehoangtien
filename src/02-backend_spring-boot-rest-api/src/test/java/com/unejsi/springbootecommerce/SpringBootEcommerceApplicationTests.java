package com.unejsi.springbootecommerce;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

@SpringBootTest
@ActiveProfiles("test")
class SpringBootEcommerceApplicationTests {

    @Test
    void contextLoads() {
        // Xác nhận Spring Boot context load thành công (dùng H2 in-memory)
    }

}
