import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';
import { TabsPage } from './tabs.page';
import { AuthGuard, ProducerGuard } from '../core/auth.guard';

const routes: Routes = [
  {
    path: 'tabs',
    component: TabsPage,
    children: [
      {
        path: 'browse',
        loadChildren: () => import('../browse/browse.module').then((m) => m.BrowsePageModule),
      },
      {
        path: 'product/:id',
        loadChildren: () => import('../product/product.module').then((m) => m.ProductPageModule),
      },
      {
        path: 'orders',
        canActivate: [AuthGuard],
        loadChildren: () => import('../orders/orders.module').then((m) => m.OrdersPageModule),
      },
      {
        path: 'producer',
        canActivate: [ProducerGuard],
        loadChildren: () => import('../producer/producer.module').then((m) => m.ProducerPageModule),
      },
      {
        path: 'profile',
        loadChildren: () => import('../profile/profile.module').then((m) => m.ProfilePageModule),
      },
      {
        path: 'auth',
        loadChildren: () => import('../auth/auth.module').then((m) => m.AuthPageModule),
      },
      {
        path: '',
        redirectTo: '/tabs/browse',
        pathMatch: 'full',
      },
    ],
  },
  {
    path: '',
    redirectTo: '/tabs/browse',
    pathMatch: 'full',
  },
];

@NgModule({
  imports: [RouterModule.forChild(routes)],
  exports: [RouterModule],
})
export class TabsPageRoutingModule {}
