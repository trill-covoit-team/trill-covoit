package fr.trill.covoit.repository;

import fr.trill.covoit.model.AppUser;
import org.springframework.data.jpa.repository.JpaRepository;

public interface AppUserRepository extends JpaRepository<AppUser, Integer> {}