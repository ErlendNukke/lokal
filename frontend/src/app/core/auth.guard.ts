import { Injectable } from '@angular/core';
import {
  ActivatedRouteSnapshot,
  CanActivate,
  Router,
  RouterStateSnapshot,
  UrlTree,
} from '@angular/router';
import { AuthService } from './auth.service';

@Injectable({ providedIn: 'root' })
export class AuthGuard implements CanActivate {
  constructor(private auth: AuthService, private router: Router) {}

  canActivate(_route: ActivatedRouteSnapshot, state: RouterStateSnapshot): boolean | UrlTree {
    if (this.auth.isLoggedIn) {
      return true;
    }
    return this.router.createUrlTree(['/tabs/auth'], {
      queryParams: { returnUrl: state.url },
    });
  }
}

@Injectable({ providedIn: 'root' })
export class ProducerGuard implements CanActivate {
  constructor(private auth: AuthService, private router: Router) {}

  canActivate(): boolean | UrlTree {
    if (this.auth.isLoggedIn && this.auth.isProducer) {
      return true;
    }
    if (!this.auth.isLoggedIn) {
      return this.router.createUrlTree(['/tabs/auth']);
    }
    return this.router.createUrlTree(['/tabs/profile']);
  }
}
