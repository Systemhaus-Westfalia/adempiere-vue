<!--
ADempiere-Vue (Frontend) for ADempiere ERP & CRM Smart Business Solution
Copyright (C) 2017-Present E.R.P. Consultores y Asociados, C.A.
This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.
-->

<template>
  <el-select
    v-model="selectedUOM"
    size="small"
    style="width: 100%;"
    @change="handleChange"
    @visible-change="loadUOMList"
  >
    <el-option
      v-for="item in uomList"
      :key="item.uom.id"
      :label="item.uom.name"
      :value="item.uom.id"
    />
  </el-select>
</template>

<script>
import { defineComponent, ref, computed, onMounted } from '@vue/composition-api'
import store from '@/store'

export default defineComponent({
  name: 'editUOM',
  props: {
    value: {
      type: Number,
      required: true
    },
    productId: {
      type: Number,
      required: true
    },
    handleChange: {
      type: Function,
      default: (newValue) => {}
    }
  },
  setup(props) {
    const selectedUOM = ref(props.value)

    const uomList = computed(() => {
      return store.getters.getListUOM({ productId: props.productId })
    })

    function loadUOMList(isVisible) {
      if (isVisible && uomList.value.length === 0) {
        store.dispatch('findListUOM', { productId: props.productId })
      }
    }

    onMounted(() => {
      store.dispatch('findListUOM', { productId: props.productId })
    })

    return {
      selectedUOM,
      uomList,
      loadUOMList
    }
  }
})
</script>
