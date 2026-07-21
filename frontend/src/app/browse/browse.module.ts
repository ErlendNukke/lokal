import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { IonicModule } from '@ionic/angular';
import { RouterModule, Routes } from '@angular/router';
import { BrowsePage } from './browse.page';
import { SharedModule } from '../shared/shared.module';

const routes: Routes = [{ path: '', component: BrowsePage }];

@NgModule({
  imports: [CommonModule, FormsModule, IonicModule, SharedModule, RouterModule.forChild(routes)],
  declarations: [BrowsePage],
})
export class BrowsePageModule {}
