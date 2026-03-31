<!--
  ADempiere-Vue (Frontend) for ADempiere ERP & CRM Smart Business Solution
  Copyright (C) 2018-Present E.R.P. Consultores y Asociados, C.A. www.erpya.com
  Contributor(s): Edwin Betancourt EdwinBetanc0urt@outlook.com https://github.com/EdwinBetanc0urt
  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program. If not, see <https:www.gnu.org/licenses/>.
-->

<template>
  <el-main
    class="product-list-content"
  >
    <el-form
      label-position="top"
      label-width="10px"
      @submit.native.prevent="notSubmitForm"
    >
      <el-form-item
        :label="$t('form.productInfo.codeProduct')"
        style="width: 100% !important;"
      >
        <el-input
          v-model="searchValue"
          :placeholder="$t('quickAccess.searchWithEnter')"
          clearable
          style="width: 100% !important;"
          @input="searchProduct"
        />
      </el-form-item>
    </el-form>
    <el-table
      v-loading="isLoading"
      :data="listProducto"
      :empty-text="$t('quickAccess.searchWithEnter')"
      highlight-current-row
      :border="true"
      height="450"
      fit
      @current-change="handleCurrentChange"
      @row-dblclick="addProduct"
    >
      <index-column
        :page-number="1"
        :page-size="50"
      />
      <el-table-column
        :label="$t('form.productInfo.code')"
        width="190"
      >
        <template slot-scope="scope">
          <el-button
            type="text"
            icon="el-icon-document-copy"
            @click="copyCode(scope.row)"
          />
          {{ scope.row.product.value }}
        </template>
      </el-table-column>
      <el-table-column
        prop="product.name"
        :label="$t('form.productInfo.name')"
        min-width="200"
      />
      <el-table-column
        prop="quantity_ordered"
        :label="$t('form.productInfo.quantityOnHand')"
        align="right"
      >
        <template slot-scope="scope">
          {{ formatQuantity({ value: scope.row.quantity_ordered }) }}
        </template>
      </el-table-column>
      <el-table-column
        :label="$t('form.productInfo.price')"
        align="right"
      >
        <template slot-scope="scope">
          {{ displayAmount(scope.row) }}
        </template>
      </el-table-column>
      <el-table-column
        :label="$t('form.pos.collect.convertedAmount')"
        align="right"
      >
        <template slot-scope="scope">
          {{ displayAmount(scope.row) }}
        </template>
      </el-table-column>
    </el-table>

    <p>
      <custom-pagination
        style="float: left;"
        :total-records="recordCount"
        :selection="selection"
        :page-number="pageToken"
        :page-size="listProducto.length"
        :handle-change-page-number="handleChangePage"
        :handle-change-page-size="handleSizeChange"
      />

      <el-button
        type="primary"
        class="button-base-icon"
        icon="el-icon-check"
        style="float: right;margin-left: 5px;"
        :disabled="isEmptyValue(selectProduct)"
        @click="addProduct(selectProduct)"
      />
      <el-button
        :loading="isLoadingRecords"
        type="success"
        class="button-base-icon"
        style="float: right;margin-left: 5px;"
        icon="el-icon-refresh-right"
        @click="refresh();"
      />
      <el-button
        type="danger"
        class="button-base-icon"
        icon="el-icon-close"
        style="float: right;"
        @click="close(false)"
      />
    </p>
  </el-main>
</template>

<script>
import { defineComponent, computed, ref } from '@vue/composition-api'

import store from '@/store'

// Constants
import {
  SEARCH_DELAY, PAGE_CHANGE_DELAY
} from '@/utils/ADempiere/tableUtils'
// Components and Mixins
import CustomPagination from '@/components/ADempiere/DataTable/Components/CustomPagination.vue'
import IndexColumn from '@/components/ADempiere/DataTable/Components/IndexColumn.vue'

// Utils and Helper Methods
import { isEmptyValue } from '@/utils/ADempiere'
import { copyToClipboard } from '@/utils/ADempiere/coreUtils.js'
import { formatPrice, formatQuantity } from '@/utils/ADempiere/formatValue/numberFormat'

export default defineComponent({
  name: 'ProductListTable',

  components: {
    IndexColumn,
    CustomPagination
  },

  setup() {
    const searchValue = ref('')
    const isLoading = ref(false)
    const isLoadingRecords = ref(false)
    const pageSizeNumber = ref(15)
    const selection = ref(0)
    const selectProduct = ref({})
    let timeoutSearch

    const listProducto = computed(() => store.getters.getProductList)
    const recordCount = computed(() => store.getters.getProductCount)
    const pageToken = computed(() => {
      const page = store.getters.getProductPageToken
      if (page) return Number(page.slice(-1))
      return 0
    })
    const order = computed(() => store.getters.getCurrentOrder)

    function copyCode(row) {
      copyToClipboard({
        text: row.product.value,
        isShowMessage: true
      })
    }

    function fetchProducts({ search = searchValue.value, pageSize = pageSizeNumber.value, pageToken } = {}) {
      return store.dispatch('searchProductList', {
        searchValue: search,
        pageSize,
        pageToken
      })
    }

    function searchProduct(search) {
      clearTimeout(timeoutSearch)
      isLoading.value = true
      timeoutSearch = setTimeout(() => {
        fetchProducts({ search })
          .finally(() => {
            isLoading.value = false
            searchValue.value = ''
          })
      }, SEARCH_DELAY)
    }

    function displayAmount(row) {
      const { price_standard, currency } = row
      return formatPrice({ value: price_standard, currency: currency.iSOCode })
    }

    function addProductLine(productId) {
      store.dispatch('newLine', { productId })
    }

    function addProduct(row) {
      if (isEmptyValue(order.value.id)) {
        store.dispatch('newOrder')
          .finally(() => addProductLine(row.product.id))
      } else {
        const existingLine = store.getters.getListOrderLines.find(
          line => line.product.id === row.product.id
        )
        if (!isEmptyValue(existingLine)) {
          const currentUomId = existingLine.uom && existingLine.uom.uom
            ? existingLine.uom.uom.id
            : undefined
          store.dispatch('updateCurrentLine', {
            lineId: existingLine.id,
            quantity: Number(existingLine.quantity) + 1,
            uom_id: currentUomId,
            isListLine: true
          })
          close(false)
          return
        }
        addProductLine(row.product.id)
      }
      close(false)
    }

    function close(show = false) {
      store.commit('setShowProductList', show)
      selectProduct.value = {}
      searchValue.value = ''
    }

    function handleCurrentChange(row) {
      if (!isEmptyValue(row)) selection.value = 1
      selectProduct.value = row
    }

    function handleSizeChange(pageSize) {
      isLoading.value = true
      pageSizeNumber.value = pageSize
      timeoutSearch = setTimeout(() => {
        fetchProducts({ pageSize })
          .finally(() => {
            isLoading.value = false
          })
      }, PAGE_CHANGE_DELAY)
    }

    function handleChangePage(pageNumber) {
      isLoading.value = true
      timeoutSearch = setTimeout(() => {
        fetchProducts({
          pageToken: store.getters.getProductPageToken + '-' + pageNumber
        })
          .finally(() => {
            isLoading.value = false
          })
      }, PAGE_CHANGE_DELAY)
    }

    function refresh() {
      isLoading.value = true
      isLoadingRecords.value = true
      fetchProducts()
        .finally(() => {
          isLoading.value = false
          isLoadingRecords.value = false
        })
    }

    return {
      // Ref
      selection,
      isLoading,
      searchValue,
      selectProduct,
      pageSizeNumber,
      isLoadingRecords,
      // Computed
      listProducto,
      recordCount,
      pageToken,
      // Methods
      handleCurrentChange,
      handleChangePage,
      handleSizeChange,
      formatQuantity,
      displayAmount,
      searchProduct,
      addProduct,
      copyCode,
      refresh,
      close
    }
  }
})
</script>

<style lang="scss">
.product-list-content {
  padding-top: 0px;
}
.el-autocomplete-suggestion li {
  line-height: 20px;
}
</style>
