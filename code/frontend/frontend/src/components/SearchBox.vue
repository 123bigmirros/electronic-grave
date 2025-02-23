<template>
    <div class="search-box">
        <input 
            type="text" 
            v-model="searchQuery" 
            placeholder="搜索..." 
            @keyup.enter="handleSearch"
        >
        <button @click="handleSearch">搜索</button>
    </div>
</template>

<script>
export default {
    name: 'SearchBox',
    data() {
        return {
            searchQuery: ''
        }
    },
    methods: {
        handleSearch() {
            // 未来实现搜索功能
            console.log('搜索:', this.searchQuery);
        }
    }
}
</script>

<style scoped>
.search-box {
    display: flex;
    align-items: center;
    gap: 10px;
}

input {
    padding: 8px;
    border: 1px solid #ddd;
    border-radius: 4px;
    width: 200px;
}

button {
    padding: 8px 15px;
    background-color: #4CAF50;
    color: white;
    border: none;
    border-radius: 4px;
    cursor: pointer;
}

button:hover {
    background-color: #45a049;
}
</style> 