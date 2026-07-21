package com.pawket.users.application;

import com.pawket.shared.error.ApiException;
import com.pawket.users.application.port.out.UserRepository;
import com.pawket.users.domain.model.User;
import jakarta.enterprise.context.ApplicationScoped;
import java.util.UUID;

@ApplicationScoped
public class UserQueryService {
    private final UserRepository users;

    public UserQueryService(UserRepository users) {
        this.users = users;
    }

    public User getCurrent(UUID actorId) {
        return users.findActiveById(actorId)
                .orElseThrow(() -> ApiException.notFound("USER_NOT_FOUND", "Current user was not found."));
    }
}
