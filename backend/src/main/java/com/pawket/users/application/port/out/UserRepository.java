package com.pawket.users.application.port.out;

import com.pawket.users.domain.model.User;
import java.util.Optional;
import java.util.UUID;

public interface UserRepository {
    Optional<User> findActiveById(UUID userId);
}
