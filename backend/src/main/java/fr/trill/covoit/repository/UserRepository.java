package fr.trill.covoit.repository;

import fr.trill.covoit.accessingData.User;
import org.springframework.data.jpa.repository.JpaRepository;

public interface UserRepository extends JpaRepository<User, Integer> {
}